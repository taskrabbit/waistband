require 'spec_helper'

describe "Waistband::Index -- CRUD" do

  let(:index)   { Waistband::Index.new('events') }
  let(:index2)  { Waistband::Index.new('search') }
  let(:attrs)   { {'ok' => {'yeah' => true}} }

  it "creates the index" do
    index.delete!
    expect{ index.refresh }.to raise_error(Elasticsearch::Transport::Transport::Errors::NotFound)

    index.create!
    expect{ index.refresh }.to_not raise_error
  end

  it "blows up when trying to create an existing index" do
    index.delete!
    expect{ index.refresh }.to raise_error(Elasticsearch::Transport::Transport::Errors::NotFound)

    expect{ index.create! }.to_not raise_error
    expect{ index.create! }.to raise_error(::Waistband::Errors::IndexExists, "Index already exists")
  end

  it "doesn't blow up on creation when using the non-bang method" do
    index.delete!
    expect{ index.refresh }.to raise_error(Elasticsearch::Transport::Transport::Errors::NotFound)

    expect{ index.create! }.to_not raise_error
    expect{ index.create }.to_not raise_error
  end

  it "deletes the index" do
    index.delete!
    expect{ index.refresh }.to raise_error(Elasticsearch::Transport::Transport::Errors::NotFound)
    index.create!
  end

  it "blows up when trying to delete an index that does not exist" do
    index.delete!
    expect { index.delete! }.to raise_error(::Waistband::Errors::IndexNotFound)
  end

  describe "storing" do

    it "stores data" do
      expect(index.save('__test_write', {'ok' => 'yeah'})).to be true
      expect(index.read('__test_write')).to eql({
        '_id' => '__test_write',
        '_index' => 'events_test',
        '_source' => {'ok' => 'yeah'},
        '_type' => 'event',
        '_version' => 1,
        'found' => true
      })
    end

    it "data is stringified" do
      index.save('__test_write', attrs)
      expect(index.read('__test_write')[:_source]).to eql({"ok"=>"{\"yeah\"=>true}"})
    end

    it "data is indirectly accessible when not stringified" do
      index2.save('__test_not_string', attrs)
      expect(index2.read('__test_not_string')[:_source][:ok][:yeah]).to eql true
    end

    it "deletes data" do
      index.save('__test_write', attrs)
      index.destroy('__test_write')
      expect(index.read('__test_write')).to be_nil
    end

    it "returns nil on 404" do
      expect(index.read('__not_here')).to be_nil
    end

    it "blows up on 404 when using the bang method" do
      expect {
        index.read!('__not_here')
      }.to raise_error(Elasticsearch::Transport::Transport::Errors::NotFound)
    end

    it "doesn't mix data between two indexes" do
      index.save('__test_write',  {'data' => 'index_1'})
      index2.save('__test_write', {'data' => 'index_2'})

      expect(index.read('__test_write')[:_source]).to   eql({'data' => 'index_1'})
      expect(index2.read('__test_write')[:_source]).to  eql({'data' => 'index_2'})
    end

    it "finds a result instead of a hash" do
      index.save('__test_write', attrs)
      result = index.read_result!('__test_write')

      expect(result).to be_present
      expect(result).to be_a Waistband::Result
      expect(result._id).to eql '__test_write'
      expect(result.ok).to eql '{"yeah"=>true}'
    end

  end

end

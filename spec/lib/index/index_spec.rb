require 'spec_helper'

describe Waistband::Index do

  let(:index)   { Waistband::Index.new('events') }
  let(:index2)  { Waistband::Index.new('search') }
  let(:attrs)   { {'ok' => {'yeah' => true}} }

  it "initializes values" do
    expect(index.instance_variable_get('@stringify')).to eql true
  end

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

  it "updates the index's mappings" do
    index = Waistband::Index.new('geo')
    expect{ index.create }.to_not raise_error

    response = index.update_mapping('geo')
    expect(response['acknowledged']).to be true
  end

  it "updates all mappings" do
    index.refresh
    responses = index.update_all_mappings
    expect(responses).to be_an Array

    response = responses.first
    expect(response['acknowledged']).to be true
    expect(response['_type']).to eql 'event'
  end

  it "updates the index's settings" do
    index.refresh
    response = index.update_settings
    expect(response['acknowledged']).to be true
  end

  it "correctly sets hosts" do
    expect(index.client.send(:hosts)).to eql([
      {host: "localhost", port: 9200, protocol: "http"},
      {host: "127.0.0.1", port: 9200, protocol: "http"}
    ])
  end

  describe "searching" do

    it "proxies to the client's search" do
      result = index.search({})
      expect(result).to be_a Waistband::SearchResults
      expect(result.took).to be_present
      expect(result.hits).to be_an Array
    end

    it "does not blow up when an index type is specified" do
      expect{ index.search({_type: 'event'}) }.to_not raise_error
    end

  end

  describe "storing" do
    it "stores data" do
      expect(index.save('__test_write', {'ok' => 'yeah'})).to be_present
      expect(index.read('__test_write')).to eql({
        '_id' => '__test_write',
        '_index' => 'events_test',
        '_source' => {'ok' => 'yeah'},
        '_type' => 'event',
        '_version' => 1,
        'found' => true
      })
    end

    it "can partially updates documents" do
      expect(index.save('__test_write', {'ok' => 'yeah', 'not_ok' => 'yeah'})).to be_present
      expect(index.update('__test_write', {'not_ok' => 'no'})).to be_present
      expect(index.read('__test_write')).to eql({
        '_id' => '__test_write',
        '_index' => 'events_test',
        '_source' => {'ok' => 'yeah', 'not_ok' => 'no'},
        '_type' => 'event',
        '_version' => 2,
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

  describe 'paginating search results' do

    it "permits paginating" do
      results = index.search(page: 5, page_size: 15)
      expect(results.instance_variable_get('@page')).to eql 5
      expect(results.instance_variable_get('@page_size')).to eql 15
    end

    it "permits passing in page_size without page" do
      results = index.search(page_size: 999)
      expect(results.instance_variable_get('@page')).to eql 1
      expect(results.instance_variable_get('@page_size')).to eql 999
    end

    describe 'with results' do

      before do
        index.delete
        index.create
        index.refresh

        index.save('__test_write1',  {'data' => 'index_1'})
        index.save('__test_write2',  {'data' => 'index_2'})
        index.save('__test_write3',  {'data' => 'index_3'})
        index.save('__test_write4',  {'data' => 'index_4'})
        index.refresh
      end

      it "respects paginating when fetching hits" do
        query = index.search(page: 1, page_size: 10)
        expect(query.hits.size).to eql 4

        query = index.search(page: 2, page_size: 10)
        expect(query.hits.size).to eql 0

        query = index.search(page: 1, page_size: 2)
        expect(query.hits.size).to eql 2
      end

      it "paginates when not passing in a page number" do
        query = index.search(page_size: 10)
        expect(query.hits.size).to eql 4

        query = index.search(page_size: 2)
        expect(query.hits.size).to eql 2
      end

      it 'returns results beyond page 1 (does not double scope)' do
        query = index.search(page_size: 2, page: 1)
        hits1 = query.hits
        expect(hits1.size).to eql 2

        query = index.search(page_size: 2, page: 2)
        hits2 = query.hits
        expect(hits2.size).to eql 2

        expect(hits1 & hits2).to be_empty
      end

    end

  end

  describe 'subindexes' do

    describe 'version option' do

      let(:sharded_index) { Waistband::Index.new('events', version: 1) }

      it 'behaves exactly like a subs specified subindex' do
        expect(sharded_index.send(:config_name)).to eql 'events_test__version_1'
        expect(sharded_index.instance_variable_get('@version')).to eql 1
      end

      it "retains the same options from the parent index config" do
        config = sharded_index.send(:config)

        expect(sharded_index.send(:base_config_name)).to eql 'events_test'
        expect(config['stringify']).to be true
        expect(config['settings']).to be_present
      end

      it "creates the sharded index with the same mappings as the parent" do
        sharded_index.delete

        expect(Waistband::Index.new('events', version: 1).exists?).to be false

        expect {
          sharded_index.create!
        }.to_not raise_error

        expect(Waistband::Index.new('events', version: 1).exists?).to be true
      end

    end

    describe 'subs option' do

      let(:sharded_index) { Waistband::Index.new('events', subs: %w(2013 01)) }

      it "permits subbing the index" do
        expect(sharded_index.send(:config_name)).to eql 'events_test__2013_01'
      end

      it "permits sharding into singles" do
        index = Waistband::Index.new 'events', subs: '2013'
        expect(index.send(:config_name)).to eql 'events_test__2013'
      end

      it "retains the same options from the parent index config" do
        config = sharded_index.send(:config)

        expect(sharded_index.send(:base_config_name)).to eql 'events_test'
        expect(config['stringify']).to be true
        expect(config['settings']).to be_present
      end

      it "creates the sharded index with the same mappings as the parent" do
        sharded_index.delete

        expect {
          sharded_index.create!
        }.to_not raise_error
      end

      describe 'no configged index name' do

        it "gets a default name that makes sense for the index when not defined" do
          index = Waistband::Index.new 'events_no_name', subs: %w(2013 01)
          expect(index.send(:config_name)).to eql 'events_no_name_test__2013_01'
        end

      end

    end

  end

  describe 'force_name' do

    let(:forced_name_index) { Waistband::Index.new 'events_no_name', force_name: 'new_forced_name' }

    around(:each) do |example|
      forced_name_index.delete
      example.run
      forced_name_index.delete
    end

    it "creates the index" do
      expect(forced_name_index.exists?).to be_falsey

      forced_name_index.create!
      expect(forced_name_index.exists?).to be_truthy
      expect(forced_name_index.send(:config_name)).to eql 'new_forced_name'
    end

  end

  describe '#base_config_name' do

    it "gets a default name that makes sense for the index when not defined" do
      index = Waistband::Index.new 'events_no_name'
      expect(index.send(:base_config_name)).to eql 'events_no_name_test'
    end

  end

  describe 'aliases' do

    it "returns the alias name with the env" do
      expect(index.send(:full_alias_name, 'all_events')).to eql 'all_events_test'
    end

    it "invoking full_alias_name doesn't mess with @index_name" do
      expect(index.instance_variable_get('@index_name')).to eql 'events'
      expect(index.send(:full_alias_name, 'all_events')).to eql 'all_events_test'
      expect(index.instance_variable_get('@index_name')).to eql 'events'
    end

    it "if the index has a custom name, the alias name doesn't automatically append the env" do
      expect(index).to receive(:config).and_return({
        'name' => 'super_custom'
      }).once
      expect(index.send(:full_alias_name, 'all_events')).to eql 'all_events'
    end

    it "creates aliases" do
      expect(index.alias_exists?('events_alias_yo')).to be false
      index.alias 'events_alias_yo'
      expect(index.alias_exists?('events_alias_yo')).to be true
    end

    describe 'versioning' do

      it "invoking full_alias_name doesn't mess with @index_name" do
        index = Waistband::Index.new('events', version: 1)
        index.delete
        index.create
        index.alias('aliased_events')

        expect(index.instance_variable_get('@index_name')).to eql 'events'
      end

    end

    it 'returns the name of the parent index' do
      index.alias('events_alias')
      alias_ref = Waistband::Index.new 'events', force_name: index.send(:full_alias_name, 'events_alias')

      parent_index_names = alias_ref.parent_index_names
      expect(parent_index_names.length).to eq(1)
      expect(parent_index_names[0]).to eq(index.send(:config_name))
    end

    it 'can return a reference to the parent index' do
      index.alias('events_alias')
      alias_ref = Waistband::Index.new 'events', force_name: index.send(:full_alias_name, 'events_alias')
      parent_index = alias_ref.get_first_parent_index_reference

      expect(parent_index.exists?).to be_truthy
      expect(parent_index.send(:config_name)).to eq(index.send(:config_name))
    end

    it "can save read and update documents from an alias" do
      index.alias('events_alias')
      alias_ref = Waistband::Index.new 'events', force_name: index.send(:full_alias_name, 'events_alias')

      expect(alias_ref.save('__test_write', {'ok' => 'yeah', 'not_ok' => 'yeah'})).to be_present
      expect(alias_ref.update('__test_write', {'not_ok' => 'no'})).to be_present
      expect(alias_ref.read('__test_write')).to eql({
        '_id' => '__test_write',
        '_index' => 'events_test',
        '_source' => {'ok' => 'yeah', 'not_ok' => 'no'},
        '_type' => 'event',
        '_version' => 2,
        'found' => true
      })
    end

    it "update_mappings from an alias" do
      index = Waistband::Index.new 'geo', force_name: 'geo_index'
      index.delete
      index.create!
      index.alias('geo_index_alias')

      alias_ref = Waistband::Index.new 'geo', force_name: 'geo_index_alias'

      responses = alias_ref.update_all_mappings
      index.delete

      expect(responses).to be_an Array

      response = responses.first
      expect(response['acknowledged']).to be_truthy
      expect(response['_type']).to eq('geo')
    end

  end

  describe 'logging' do

    before do
      Waistband.config.logger = FakeLog.new
    end

    it "sets the index's client transport logger" do
      expect(index2.client.transport.logger).to be_a FakeLog
      expect(index2.client.transport.logger.level).to eql 2
    end

    it "logs" do
      expect(Waistband.config.logger).to receive(:info).with(kind_of(String)).once
      index2.search({})
    end

  end

  describe '#delete_by_query' do
    let(:delete_query) { { query: { match_all: {} } } }
    let(:result) { index.delete_by_query(delete_query) }

    before do
      index.save('__test_write1',  {'data' => 'index_1'})
      index.save('__test_write2',  {'data' => 'index_2'})
      index.refresh
    end

    it "returns a DeleteByQueryResult object with expected properties" do
      expect(result).to be_a Waistband::DeleteByQueryResult
      expect(result.deleted).to eq(2)
      expect(result.full_response).to be_a Hash
    end
  end
end

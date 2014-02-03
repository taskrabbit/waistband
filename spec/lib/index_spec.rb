require 'spec_helper'

describe Waistband::Index do

  let(:index)   { Waistband::Index.new('events') }
  let(:index2)  { Waistband::Index.new('search') }
  let(:attrs)   { {'ok' => {'yeah' => true}} }

  it "initializes values" do
    index.instance_variable_get('@stringify').should  eql true
  end

  it "creates the index" do
    index.destroy!
    expect{ index.refresh! }.to raise_error(Waistband::Connection::Error::Resquest)

    index.create!
    expect{ index.refresh! }.to_not raise_error
  end

  it "destroys the index" do
    index.destroy!
    expect{ index.refresh! }.to raise_error(Waistband::Connection::Error::Resquest)
    index.create!
  end

  it "updates the index's settings" do
    index.refresh
    response = JSON.parse(index.update_settings!)
    response['ok'].should be_true
  end

  it "proxies to a query" do
    index.query.should be_a Waistband::Query
  end

  describe "storing" do

    it "stores data" do
      index.store!('__test_write', {'ok' => 'yeah'})
      index.read('__test_write').should eql({'ok' => 'yeah'})
    end

    it "data is stringified" do
      index.store!('__test_write', attrs)
      index.read('__test_write').should eql({"ok"=>"{\"yeah\"=>true}"})
    end

    it "data is indirectly accessible when not stringified" do
      index2.store!('__test_not_string', attrs)
      index2.read('__test_not_string')[:ok][:yeah].should eql true
    end

    it "deletes data" do
      index.store!('__test_write', attrs)
      index.delete!('__test_write')
      index.read('__test_write').should be_nil
    end

    it "returns nil on 404" do
      index.read('__not_here').should be_nil
    end

    it "doesn't mix data between two indexes" do
      index.store!('__test_write',  {'data' => 'index_1'})
      index2.store!('__test_write', {'data' => 'index_2'})

      index.read('__test_write').should   eql({'data' => 'index_1'})
      index2.read('__test_write').should  eql({'data' => 'index_2'})
    end

  end

  describe 'subindexes' do

    let(:sharded_index) { Waistband::Index.new('events', subs: %w(2013 01)) }

    it "permits subbing the index" do
      sharded_index.name.should eql 'events__2013_01'
      sharded_index.config_name.should eql 'events_test__2013_01'
    end

    it "permits sharding into singles" do
      index = Waistband::Index.new 'events', subs: '2013'
      index.name.should eql 'events__2013'
      index.config_name.should eql 'events_test__2013'
    end

    it "retains the same options from the parent index config" do
      config = sharded_index.send(:config)

      sharded_index.base_config_name.should eql 'events_test'
      config['stringify'].should be_true
      config['settings'].should be_present
    end

    it "creates the sharded index with the same mappings as the parent" do
      sharded_index.destroy

      expect {
        sharded_index.create!
      }.to_not raise_error
    end

    describe 'no configged index name' do

      it "gets a default name that makes sense for the index when not defined" do
        index = Waistband::Index.new 'events_no_name', subs: %w(2013 01)
        index.config_name.should eql 'events_no_name_test__2013_01'
      end

    end

  end

  describe '#base_config_name' do

    it "gets a default name that makes sense for the index when not defined" do
      index = Waistband::Index.new 'events_no_name'
      index.base_config_name.should eql 'events_no_name_test'
    end

  end

end

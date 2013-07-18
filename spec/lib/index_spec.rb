require 'spec_helper'

describe Waistband::Index do

  let(:index) { Waistband::Index.new('events') }
  let(:attrs) { {'ok' => {'yeah' => true}} }

  it "initializes values" do
    index.instance_variable_get('@index_name').should eql 'events_test'
    index.instance_variable_get('@stringify').should  eql true
    index.instance_variable_get('@retries').should    eql 0
  end

  it "creates the index" do
    index.destroy!
    expect{ index.refresh }.to raise_error(RestClient::ResourceNotFound)

    index.create!
    expect{ index.refresh }.to_not raise_error
  end

  it "destroys the index" do
    index.destroy!
    expect{ index.refresh }.to raise_error(RestClient::ResourceNotFound)
  end

  it "updates the index's settings" do
    response = JSON.parse(index.update_settings!)
    response['ok'].should be_true
  end

  it "constructs the settings json" do
    index.send(:settings_json).should eql '{"index":{"number_of_replicas":1}}'
  end

  it "constructs the index json" do
    index.send(:index_json).should eql '{"settings":{"index":{"number_of_shards":4,"number_of_replicas":1}},"mappings":{"event":{"_source":{"includes":["*"]}}}}'
  end

  it "proxies to a query" do
    index.query('shopping').should be_a Waistband::Query
  end

  describe "storing" do

    before { index.store!('__test_write', attrs) }

    it "stores data" do
      index.read('__test_write').should eql attrs
    end

    it "data is indirectly accessible" do
      index.read('__test_write')[:ok][:yeah].should eql true
    end

    it "deletes data" do
      index.delete!('__test_write')
      index.read('__test_write').should be_nil
    end

    it "returns nil on 404" do
      index.read('__not_here').should be_nil
    end

    it "doesn't mix data between two indexes" do
      index2 = Waistband::Index.new('search')

      index.store!('__test_write',  {'data' => 'index_1'})
      index2.store!('__test_write', {'data' => 'index_2'})

      index.read('__test_write').should   eql({'data' => 'index_1'})
      index2.read('__test_write').should  eql({'data' => 'index_2'})
    end

  end

end

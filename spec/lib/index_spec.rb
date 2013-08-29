require 'spec_helper'

describe Waistband::Index do

  let(:index)   { Waistband::Index.new('events') }
  let(:index2)  { Waistband::Index.new('search') }
  let(:attrs)   { {'ok' => {'yeah' => true}} }

  it "initializes values" do
    index.instance_variable_get('@index_name').should eql 'events_test'
    index.instance_variable_get('@stringify').should  eql true
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
    index.create!
  end

  it "updates the index's settings" do
    index.refresh
    response = JSON.parse(index.update_settings!)
    response['ok'].should be_true
  end

  it "proxies to a query" do
    index.query('shopping').should be_a Waistband::Query
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

end

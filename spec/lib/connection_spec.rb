require 'spec_helper'

describe Waistband::Connection do

  let(:connection) { Waistband::Connection.new }

  def blacklist_server!
    connection.send(:blacklist!, Waistband.config.servers.first)
  end

  it "constructs the settings json" do
    connection.send(:settings_json, 'events').should eql '{"index":{"number_of_replicas":1}}'
  end

  it "constructs the index json" do
    connection.send(:index_json, 'events').should eql '{"settings":{"index":{"number_of_shards":4,"number_of_replicas":1}},"mappings":{"event":{"_source":{"includes":["*"]}}}}'
  end

  describe '#execute!' do

    it "wraps directly to rest client" do
      connection = Waistband::Connection.new(orderly: true)

      RestClient.should_receive(:get).with('http://localhost:9200/somekey', nil).once
      connection.send(:execute!, 'get', 'somekey')
    end

    describe 'failures' do

      [Timeout::Error, Errno::EHOSTUNREACH, Errno::ECONNREFUSED].each do |exception|
        it "blacklists the server when #{exception}" do
          connection = Waistband::Connection.new(retry_on_fail: false)

          RestClient.should_receive(:get).with(kind_of(String), nil).and_raise exception
          connection.send(:execute!, 'get', 'somekey')

          connection.send(:available_servers).size.should eql 1
        end
      end

      it "blacklists correctly when server is not responding" do
        ::Waistband.config.stub(:servers).and_return(
          [
            {
              host: "http://localhost",
              port: 9123,
              _id: "567890a5ce74182e5cd123e299993ab510c56123"
            }.with_indifferent_access,
            {
              host: "http://localhost",
              port: 9200,
              _id: "282f32a5ce74182e5cd628e298b93ab510c5660c"
            }.with_indifferent_access
          ]
        )

        connection = Waistband::Connection.new(orderly: true)
        expect { connection.refresh('events') }.to_not raise_error
      end

      it "keeps retrying till out of servers when retry_on_fail is true" do
        RestClient.should_receive(:get).with('http://localhost:9200/somekey', nil).once.and_raise(Timeout::Error)
        RestClient.should_receive(:get).with('http://127.0.0.1:9200/somekey', nil).once.and_raise(Timeout::Error)

        expect {
          connection.send(:execute!, 'get', 'somekey')
        }.to raise_error(
          Waistband::Connection::NoMoreServers,
          "No available servers remain"
        )
      end

    end

  end

  describe '#relative_url_for_key' do

    it "returns the relative url for a key" do
      url = connection.send(:relative_url_for_key, 'search', 'key123')
      url.should match /^search_test\/search\/key123$/

      url = connection.send(:relative_url_for_key, 'events', '9986')
      url.should match /^events_test\/event\/9986$/
    end

  end

  describe '#relative_url_for_index' do

    it "returns the url for an index" do
      url = connection.send(:relative_url_for_index, 'search')
      url.should match /^search_test$/

      url = connection.send(:relative_url_for_index, 'events')
      url.should match /^events_test$/
    end

  end

  describe '#url' do

    it "returns url string for the selected server" do
      url = connection.send(:url)
      url.should match /^http\:\/\//
      url.should match /\:9200$/
    end

  end

  describe '#pick_server' do

    it "randomly picks a server" do
      server = connection.send :pick_server
      server['host'].should match /http\:\/\//
      server['port'].should eql 9200
    end

    it "never picks blacklisted servers" do
      blacklist_server!

      200.times do
        server = connection.send :pick_server

        server['host'].should eql 'http://127.0.0.1'
      end
    end

    it "blows up when no more servers remain" do
      blacklist_server!

      expect {
        connection.send(:blacklist!, Waistband.config.servers.last)
      }.to raise_error(
        Waistband::Connection::NoMoreServers,
        "No available servers remain"
      )
    end

  end

  describe '#blacklist!' do

    it "blacklists a server" do
      connection.instance_variable_get('@blacklist').should be_empty

      blacklist_server!

      connection.instance_variable_get('@blacklist').size.should eql 1
      connection.instance_variable_get('@blacklist').first.should eql Waistband.config.servers.first['_id']
    end

    it "doesn't keep duplicate servers" do
      connection.instance_variable_get('@blacklist').should be_empty

      blacklist_server!

      connection.instance_variable_get('@blacklist').size.should eql 1

      blacklist_server!

      connection.instance_variable_get('@blacklist').size.should eql 1
    end

  end

  describe '#available_servers' do

    it "returns an array of servers" do
      connection.send(:available_servers).should be_an Array
      connection.send(:available_servers).size.should eql 2
    end

    it "doesn't include blacklisted servers" do
      blacklist_server!

      connection.send(:available_servers).should be_an Array
      connection.send(:available_servers).size.should eql 1

      ids = connection.send(:available_servers).map{|s| s['_id']}
      ids.should      include Waistband.config.servers.last['_id']
      ids.should_not  include Waistband.config.servers.first['_id']
    end

  end

  describe "storing" do

    let(:index)   { ::Waistband::Index.new('events') }
    let(:index2)  { ::Waistband::Index.new('search') }
    let(:attrs)   { {'ok' => {'yeah' => true}} }

    before { IndexHelper.prepare! }

    it "stores data" do
      connection.put('events', '__test_write', {'ok' => 'yeah'})
      index.read('__test_write').should eql({'ok' => 'yeah'})
    end

    it "data is indirectly accessible" do
      connection.put('events', '__test_not_string', attrs)
      index.read('__test_not_string')[:ok][:yeah].should eql true
    end

    it "deletes data" do
      connection.put('events', '__test_write', attrs)
      connection.delete!('events', '__test_write')
      index.read('__test_write').should be_nil
    end

    it "returns nil on 404" do
      index.read('__not_here').should be_nil
    end

    it "doesn't mix data between two indexes" do
      connection.put('events', '__test_write',  {'data' => 'index_1'})
      connection.put('search', '__test_write', {'data' => 'index_2'})

      index.read('__test_write').should   eql({'data' => 'index_1'})
      index2.read('__test_write').should  eql({'data' => 'index_2'})
    end

  end

end

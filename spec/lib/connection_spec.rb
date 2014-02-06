require 'spec_helper'

describe Waistband::Connection do

  let(:connection) { Waistband::Connection.new(index) }
  let(:search_connection) { Waistband::Connection.new(index_search) }
  let(:index) { ::Waistband::Index.new('events') }
  let(:index_search) { ::Waistband::Index.new('search') }

  def blacklist_server!
    connection.send(:blacklist!, Waistband.config.servers.first)
  end

  it "constructs the settings json" do
    connection.send(:settings_json).should eql '{"index":{"number_of_replicas":1}}'
  end

  it "constructs the index json" do
    connection.send(:index_json).should eql '{"settings":{"index":{"number_of_shards":1,"number_of_replicas":1}},"mappings":{"event":{"_source":{"includes":["*"]}}}}'
  end

  describe 'urls for subindexes' do

    let(:index) { ::Waistband::Index.new('events', subs: %w(2013 01)) }
    let(:connection) { Waistband::Connection.new(index, orderly: true) }

    describe '#destroy!' do

      it "targets the correct url" do
        RestClient.should_receive(:send).with('delete', "http://localhost:9200/events_test__2013_01", nil).once
        connection.destroy!
      end

    end

    describe '#create!' do

      it "targets the correct url" do
        RestClient.should_receive(:send).with('post', "http://localhost:9200/events_test__2013_01", index.config_json).once
        connection.create!
      end

    end

    describe '#update_settings!' do

      it "targets the correct url" do
        RestClient.should_receive(:send).with('put', "http://localhost:9200/events_test__2013_01/_settings", connection.send(:settings_json)).once
        connection.update_settings!
      end

    end

    describe '#refresh!' do

      it "targets the correct url" do
        RestClient.should_receive(:send).with('post', "http://localhost:9200/events_test__2013_01/_refresh", {}).once
        connection.refresh!
      end

    end

    describe '#read' do

      it "targets the correct url" do
        RestClient.should_receive(:send).with('get', "http://localhost:9200/events_test__2013_01/event/my_key", nil).once.and_call_original
        connection.read 'my_key'
      end

    end

    describe '#put' do

      it "targets the correct url" do
        RestClient.should_receive(:send).with('put', "http://localhost:9200/events_test__2013_01/event/my_key", {oh_yeah: true}.to_json).once.and_call_original
        connection.put 'my_key', {oh_yeah: true}
      end

    end

    describe '#delete!' do

      it "targets the correct url" do
        RestClient.should_receive(:send).with('delete', "http://localhost:9200/events_test__2013_01/event/my_key", nil).once.and_call_original
        connection.delete 'my_key'
      end

    end

    describe '#search_url' do

      it "targets the correct url" do
        connection.search_url.should eql "http://localhost:9200/events_test__2013_01/_search"
      end

    end

    describe '#alias!' do

      it "targets the correct url with a specific alias_name" do
        RestClient.should_receive(:send).with('put', "http://localhost:9200/events_test__2013_01/_alias/all_events_test", nil).once.and_call_original
        connection.alias! 'all_events'
      end

    end

  end

  describe '#full_alias_name' do

    it "returns the alias name with the env" do
      connection.full_alias_name('all_events').should eql 'all_events_test'
    end

    it "if the index has a custom name, the alias name doesn't automatically append the env" do
      connection.instance_variable_get('@index').stub(:config).and_return({
        'name' => 'super_custom'
      })
      connection.full_alias_name('all_events').should eql 'all_events'
    end

  end

  describe 'urls' do

    let(:connection) { Waistband::Connection.new(index, orderly: true) }

    describe '#destroy!' do

      it "targets the correct url" do
        RestClient.should_receive(:send).with('delete', "http://localhost:9200/events_test", nil).once
        connection.destroy!
      end

    end

    describe '#create!' do

      it "targets the correct url" do
        RestClient.should_receive(:send).with('post', "http://localhost:9200/events_test", index.config_json).once
        connection.create!
      end

    end

    describe '#update_settings!' do

      it "targets the correct url" do
        RestClient.should_receive(:send).with('put', "http://localhost:9200/events_test/_settings", connection.send(:settings_json)).once
        connection.update_settings!
      end

    end

    describe '#refresh!' do

      it "targets the correct url" do
        RestClient.should_receive(:send).with('post', "http://localhost:9200/events_test/_refresh", {}).once
        connection.refresh!
      end

    end

    describe '#read' do

      it "targets the correct url" do
        RestClient.should_receive(:send).with('get', "http://localhost:9200/events_test/event/my_key", nil).once.and_call_original
        connection.read 'my_key'
      end

    end

    describe '#put' do

      it "targets the correct url" do
        RestClient.should_receive(:send).with('put', "http://localhost:9200/events_test/event/my_key", {oh_yeah: true}.to_json).once.and_call_original
        connection.put 'my_key', {oh_yeah: true}
      end

    end

    describe '#delete!' do

      it "targets the correct url" do
        connection.put 'my_key', {oh_yeah: true}

        RestClient.should_receive(:send).with('delete', "http://localhost:9200/events_test/event/my_key", nil).once.and_call_original
        connection.delete! 'my_key'
      end

    end

    describe '#search_url' do

      it "targets the correct url" do
        connection.search_url.should eql "http://localhost:9200/events_test/_search"
      end

    end

    describe '#alias!' do

      it "targets the correct url with a specific alias_name" do
        RestClient.should_receive(:send).with('put', "http://localhost:9200/events_test/_alias/all_events_test", nil).once.and_call_original
        connection.alias! 'all_events'
      end

    end

  end

  describe '#alias!' do

    it "creates an alias for the index" do
      connection.alias! 'all_events'
      aliases = connection.fetch_alias 'all_events'
      aliases.should eql({"events_test"=>{"aliases"=>{"all_events_test"=>{}}}})
    end

  end

  describe '#execute!' do

    it "wraps directly to rest client" do
      connection = Waistband::Connection.new(index, orderly: true)

      RestClient.should_receive(:get).with('http://localhost:9200/somekey', nil).once
      connection.send(:execute!, 'get', 'somekey')
    end

    describe 'failures' do

      [Timeout::Error, Errno::EHOSTUNREACH, Errno::ECONNREFUSED, Errno::ECONNRESET].each do |exception|
        it "blacklists the server when #{exception}" do
          connection = Waistband::Connection.new(index, retry_on_fail: false)

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

        connection = Waistband::Connection.new(index, orderly: true)
        expect { connection.refresh }.to_not raise_error

        connection.instance_variable_get('@blacklist').should eql ['567890a5ce74182e5cd123e299993ab510c56123']
      end

      it "keeps retrying till out of servers when retry_on_fail is true" do
        RestClient.should_receive(:get).with('http://localhost:9200/somekey', nil).once.and_raise(Timeout::Error)
        RestClient.should_receive(:get).with('http://127.0.0.1:9200/somekey', nil).once.and_raise(Timeout::Error)

        expect {
          connection.send(:execute!, 'get', 'somekey')
        }.to raise_error(
          Waistband::Connection::Error::NoMoreServers,
          "No available servers remain"
        )
      end

    end

  end

  describe '#relative_url_for_key' do

    it "returns the relative url for a key" do
      url = search_connection.send(:relative_url_for_key, 'key123')
      url.should match /^search_test\/search\/key123$/

      url = connection.send(:relative_url_for_key, '9986')
      url.should match /^events_test\/event\/9986$/
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
        Waistband::Connection::Error::NoMoreServers,
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

    let(:attrs)   { {'other_ok' => {'yeah' => true}} }

    it "stores data" do
      connection.put('__test_write', {'ok' => 'yeah'})
      index.read('__test_write').should eql({'ok' => 'yeah'})
    end

    it "data is indirectly accessible" do
      connection.put('__test_not_string', attrs)
      index.read('__test_not_string')[:other_ok][:yeah].should eql true
    end

    it "deletes data" do
      connection.put('__test_write', attrs)
      connection.delete!('__test_write')
      index.read('__test_write').should be_nil
    end

    it "blows up when trying to delete non-existent data" do
      expect { connection.delete!('__test_write') }.to raise_error
    end

    it "returns nil on 404" do
      index.read('__not_here').should be_nil
    end

    it "doesn't mix data between two indexes" do
      connection.put('__test_write',  {'data' => 'index_1'})
      search_connection.put('__test_write', {'data' => 'index_2'})

      index.read('__test_write').should   eql({'data' => 'index_1'})
      index_search.read('__test_write').should  eql({'data' => 'index_2'})
    end

  end

end

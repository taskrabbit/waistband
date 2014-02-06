require 'spec_helper'

describe Waistband::Configuration do

  let(:config) { Waistband.config }

  it "loads config yml" do
    config.host.should match /http\:\/\//
    config.port.should eql 9200
    config.timeout.should eql 2
  end

  it "loads indexes config" do
    config.index('search').should be_a Hash
    config.index('search')['settings']['index']['number_of_shards'].should eql 1
  end

  it "loads multiple indexes config" do
    config.index('events').should be_a Hash
    config.index('events')['settings']['index']['number_of_shards'].should eql 1
  end

  describe '#servers' do

    it "returns array of all available servers' configs" do
      config.servers.should be_an Array
      config.servers.size.should eql 2

      config.servers.each_with_index do |server, i|
        server['host'].should match /http\:\/\//
        server['port'].should eql 9200

        server['_id'].should be_present
        server['_id'].length.should eql 40
      end
    end

    it "servers ids should be unique" do
      config.servers[0]['_id'].should_not eql config.servers[1]['_id']
    end

  end

end

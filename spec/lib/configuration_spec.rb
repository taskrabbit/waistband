require 'spec_helper'

describe Waistband::Configuration do

  let(:config) { Waistband.config }

  it "loads config yml" do
    expect(config.timeout).to eql 2
  end

  it "loads indexes config" do
    expect(config.index('search')).to be_a Hash
    expect(config.index('search')['settings']['index']['number_of_shards']).to eql 1
  end

  it "loads multiple indexes config" do
    config.index('events').should be_a Hash
    expect(config.index('events')['settings']['index']['number_of_shards']).to eql 1
  end

  it "proxies the client" do
    expect(::Waistband.config.client).to be_a ::Elasticsearch::Transport::Client
    expect(::Waistband.client).to be_a ::Elasticsearch::Transport::Client
  end

  describe '#hosts' do

    it "returns array of all available servers' configs" do
      expect(config.hosts).to be_an Array
      expect(config.hosts.size).to eql 2

      config.hosts.each_with_index do |server, i|
        expect(server['host']).to match /127\.0\.0\.1|localhost/
        expect(server['port']).to eql 9200
        expect(server['protocol']).to eql 'http'
      end
    end

  end

end

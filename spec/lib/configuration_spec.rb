require 'spec_helper'

describe Suspenders::Configuration do

  let(:config) { Suspenders.config }

  it "loads config yml" do
    expect(config.timeout).to eql 2
  end

  it "loads indexes config" do
    expect(config.index('search')).to be_a Hash
    expect(config.index('search')['settings']['index']['number_of_shards']).to eql 1
  end

  it "loads multiple indexes config" do
    expect(config.index('events')).to be_a Hash
    expect(config.index('events')['settings']['index']['number_of_shards']).to eql 1
  end

  it "proxies the client" do
    expect(::Suspenders.config.client).to be_a ::Suspenders::Client
    expect(::Suspenders.config.client.connection).to be_a ::Stretchysearch::Transport::Client
    expect(::Suspenders.client).to be_a ::Suspenders::Client
  end

  it "permits passing in an adapter to use to the client" do
    original_config = YAML.load_file(File.join(::Suspenders.config.config_dir, 'suspenders.yml'))['test']

    expect(::Suspenders.config.instance_variable_get('@adapter')).to be_nil

    expect(YAML).to receive(:load).and_return({'test' => original_config.merge({'adapter' => :net_http})}).at_least(:once)
    ::Suspenders.config.setup
    expect(::Suspenders.config.instance_variable_get('@adapter')).to eql :net_http
    expect(::Suspenders.client.transport.options[:adapter]).to eql :net_http
  end

  it "permits changing the timeout on command" do
    expect(::Suspenders.config.send(:timeout)).to eql 2
    ::Suspenders.config.timeout = 10
    expect(::Suspenders.config.send(:timeout)).to eql 10
    ::Suspenders.config.reset_timeout
    expect(::Suspenders.config.send(:timeout)).to eql 2
  end

  it "allows setting false config values" do
    expect(config.extra_falsy_config).to eql false
  end

  describe 'hosts' do

    it "returns array of all available servers' configs" do
      hosts = config.client.send(:hosts)
      expect(hosts).to be_an Array
      expect(hosts.size).to eql 2

      # TODO set back to 9200
      hosts.each_with_index do |server, i|
        expect(server['host']).to match(/127\.0\.0\.1|localhost/)
        expect(server['port']).to eql 9500
        expect(server['protocol']).to eql 'http'
      end
    end

  end

end

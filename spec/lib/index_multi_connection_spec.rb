require 'spec_helper'

describe Suspenders::Index do

  let(:index) { Suspenders::Index.new('multi_connection_events') }
  let(:client) { index.client }

  it "grabs connection data from the index's settings" do
    expect(client).to be_a(::Suspenders::Client)
    expect(client.connection).to be_a(::Stretchysearch::Transport::Client)
    expect(client.instance_variable_get('@servers')).to eql({"server1"=>{"host"=>"127.0.0.1", "port"=>9200, "protocol"=>"http"}})
  end

  it "correctly sets hosts" do
    expect(client.send(:config_hash)[:hosts]).to eql([{"host"=>"127.0.0.1", "port"=>9200, "protocol"=>"http"}])
  end

  it "exposes servers correctly" do
    expect(client.servers).to eql({"server1"=>{"host"=>"127.0.0.1", "port"=>9200, "protocol"=>"http"}})
  end

  it "works" do
    index.delete
    index.create
    saved = index.save('testing123', {ok: 'yeah'})
    index.refresh
    data = index.read('testing123')
    expect(data['_source']['ok']).to eql 'yeah'
  end

end

require 'spec_helper'

describe Waistband::Index do

  let(:index) { Waistband::Index.new('multi_connection_events') }

  it "grabs connection data from the index's settings" do
    client = index.client
    expect(client).to be_a(::Waistband::Client)
    expect(client.connection).to be_a(::Elasticsearch::Transport::Client)
    expect(client.instance_variable_get('@servers')).to eql({"server1"=>{"host"=>"127.0.0.1", "port"=>9200, "protocol"=>"http"}})
  end

  it "works" do
    index.delete
    index.create
    index.save('testing123', {ok: 'yeah'})
    index.refresh
    data = index.read('testing123')
    expect(data['_source']['ok']).to eql 'yeah'
  end

end

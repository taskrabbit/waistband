require 'spec_helper'

describe Waistband::Configuration do

  let(:config) { Waistband.config }

  it "loads config yml" do
    config.host.should eql 'http://localhost'
    config.port.should eql 9200
  end

  it "loads indexes config" do
    config.index('search').should be_a Hash
    config.index('search')['name'].should eql 'search_test'
    config.index('search')['settings']['number_of_shards'].should eql 4
  end

  it "loads multiple indexes config" do
    config.index('events').should be_a Hash
    config.index('events')['name'].should eql 'events_test'
    config.index('events')['settings']['number_of_shards'].should eql 4
  end

end

require 'spec_helper'

describe Waistband::Index do

  let(:index)  { Waistband::Index.new('events') }
  let(:index2) { Waistband::Index.new('search') }

  it "initializes values" do
    expect(index.instance_variable_get('@stringify')).to eql true
  end

  it "updates the index's mappings" do
    index = Waistband::Index.new('geo')
    expect{ index.create }.to_not raise_error

    response = index.update_mapping('geo')
    expect(response['acknowledged']).to be true
  end

  it "updates all mappings" do
    index.refresh
    responses = index.update_all_mappings
    expect(responses).to be_an Array

    response = responses.first
    expect(response['acknowledged']).to be true
    expect(response['_type']).to eql 'event'
  end

  it "updates the index's settings" do
    index.refresh
    response = index.update_settings
    expect(response['acknowledged']).to be true
  end

  it "correctly sets hosts" do
    expect(index.client.send(:hosts)).to eql([
      {"host" => "localhost", "port" => 9200, "protocol" => "http"},
      {"host" => "127.0.0.1", "port" => 9200, "protocol" => "http"}
    ])
  end

  describe 'subindexes' do

    describe 'version option' do

      let(:sharded_index) { Waistband::Index.new('events', version: 1) }

      it 'behaves exactly like a subs specified subindex' do
        expect(sharded_index.send(:config_name)).to eql 'events_test__version_1'
        expect(sharded_index.instance_variable_get('@version')).to eql 1
      end

      it "retains the same options from the parent index config" do
        config = sharded_index.send(:config)

        expect(sharded_index.send(:base_config_name)).to eql 'events_test'
        expect(config['stringify']).to be true
        expect(config['settings']).to be_present
      end

      it "creates the sharded index with the same mappings as the parent" do
        sharded_index.delete

        expect(Waistband::Index.new('events', version: 1).exists?).to be false

        expect {
          sharded_index.create!
        }.to_not raise_error

        expect(Waistband::Index.new('events', version: 1).exists?).to be true
      end

    end

    describe 'subs option' do

      let(:sharded_index) { Waistband::Index.new('events', subs: %w(2013 01)) }

      it "permits subbing the index" do
        expect(sharded_index.send(:config_name)).to eql 'events_test__2013_01'
      end

      it "permits sharding into singles" do
        index = Waistband::Index.new 'events', subs: '2013'
        expect(index.send(:config_name)).to eql 'events_test__2013'
      end

      it "retains the same options from the parent index config" do
        config = sharded_index.send(:config)

        expect(sharded_index.send(:base_config_name)).to eql 'events_test'
        expect(config['stringify']).to be true
        expect(config['settings']).to be_present
      end

      it "creates the sharded index with the same mappings as the parent" do
        sharded_index.delete

        expect {
          sharded_index.create!
        }.to_not raise_error
      end

      describe 'no configged index name' do

        it "gets a default name that makes sense for the index when not defined" do
          index = Waistband::Index.new 'events_no_name', subs: %w(2013 01)
          expect(index.send(:config_name)).to eql 'events_no_name_test__2013_01'
        end

      end

    end

  end

  describe '#base_config_name' do

    it "gets a default name that makes sense for the index when not defined" do
      index = Waistband::Index.new 'events_no_name'
      expect(index.send(:base_config_name)).to eql 'events_no_name_test'
    end

  end

  describe 'aliases' do

    it "returns the alias name with the env" do
      expect(index.send(:full_alias_name, 'all_events')).to eql 'all_events_test'
    end

    it "invoking full_alias_name doesn't mess with @index_name" do
      expect(index.instance_variable_get('@index_name')).to eql 'events'
      expect(index.send(:full_alias_name, 'all_events')).to eql 'all_events_test'
      expect(index.instance_variable_get('@index_name')).to eql 'events'
    end

    it "if the index has a custom name, the alias name doesn't automatically append the env" do
      expect(index).to receive(:config).and_return({
        'name' => 'super_custom'
      }).once
      expect(index.send(:full_alias_name, 'all_events')).to eql 'all_events'
    end

    it "creates aliases" do
      expect(index.alias_exists?('events_alias_yo')).to be false
      index.alias 'events_alias_yo'
      expect(index.alias_exists?('events_alias_yo')).to be true
    end

    describe 'versioning' do

      it "invoking full_alias_name doesn't mess with @index_name" do
        index = Waistband::Index.new('events', version: 1)
        index.delete
        index.create
        index.alias('aliased_events')

        expect(index.instance_variable_get('@index_name')).to eql 'events'
      end

    end

  end

  describe 'logging' do

    before do
      Waistband.config.logger = FakeLog.new
    end

    it "sets the index's client transport logger" do
      expect(index2.client.transport.logger).to be_a FakeLog
      expect(index2.client.transport.logger.level).to eql 2
    end

    it "logs" do
      expect(Waistband.config.logger).to receive(:info).with(kind_of(String)).once
      index2.search({})
    end

  end

end

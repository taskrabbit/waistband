require 'spec_helper'

describe ::Waistband::Migrator do

  let(:migrator) { ::Waistband::Migrator.new }

  describe '#config' do

    let(:config) { migrator.send(:config) }

    it "fetches the config yml defined by the app" do
      expect(config['indices']).to eql %w(events search geo)
    end

  end

  describe '#create_indices' do

    it "creates all indices as defined by the schema" do
      IndexHelper.delete_all

      expect(::Waistband::Index.new('events').exists?).to be_false
      expect(::Waistband::Index.new('search').exists?).to be_false
      expect(::Waistband::Index.new('geo').exists?).to be_false

      response = migrator.create_indices

      expect(response).to be_a Hash
      expect(response[:events]).to be_true
      expect(response[:search]).to be_true
      expect(response[:geo]).to be_true

      expect(::Waistband::Index.new('events').exists?).to be_true
      expect(::Waistband::Index.new('search').exists?).to be_true
      expect(::Waistband::Index.new('geo').exists?).to be_true
    end

    it "shows in the response if one index creation failed" do
      ::Waistband::Index.any_instance.stub(:create).and_return(false)

      response = migrator.create_indices

      expect(response).to be_a Hash
      expect(response[:events]).to be_false
      expect(response[:search]).to be_false
      expect(response[:geo]).to be_false
    end

  end

  describe '#create_aliases' do

    it "creates all indices behind an alias" do
      IndexHelper.delete_all

      expect(::Waistband::Index.new('tasks_opened').exists?).to be_false
      expect(::Waistband::Index.new('tasks_closed').exists?).to be_false

      response = migrator.create_aliases

      expect(response).to be_a Hash
      expect(response[:tasks][:tasks_opened]).to be_true
      expect(response[:tasks][:tasks_closed]).to be_true

      expect(::Waistband::Index.new('tasks_opened').exists?).to be_true
      expect(::Waistband::Index.new('tasks_closed').exists?).to be_true
    end

    it "creates an alias for all the created indices" do
      IndexHelper.delete_all

      expect(::Waistband::Index.new('tasks_opened').alias_exists?('tasks')).to be_false
      expect(::Waistband::Index.new('tasks_closed').alias_exists?('tasks')).to be_false

      migrator.create_aliases

      expect(::Waistband::Index.new('tasks_opened').alias_exists?('tasks')).to be_true
      expect(::Waistband::Index.new('tasks_closed').alias_exists?('tasks')).to be_true
    end

    it "if it finds an index that's not defined in the alias schema, it deletes it" do
      index = ::Waistband::Index.new('tasks_assigned')

      expect(index.delete).to be_true
      expect(index.exists?).to be_false

      expect(index.create).to be_true
      expect(index.exists?).to be_true
      expect(index.alias('tasks')).to be_true

      migrator.create_aliases

      expect(index.exists?).to be_false
    end

    it "doesn't delete indices that are specified in the yml" do
      expect(::Waistband::Index.any_instance).to receive(:delete).never
      migrator.create_aliases
      migrator.create_aliases
    end

  end

end

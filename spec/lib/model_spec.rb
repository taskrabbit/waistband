require 'spec_helper'

describe Waistband::Model do


  class TestModel < Waistband::Model

    index_name :geo
    index_type :geo

    defaults important: true, shenanigans: 1

    validates :work_area, presence: true

    before_validation :set_fake_attrs
    before_create :set_more_fake_attrs

    def set_fake_attrs
      self.fake1 = 'uno'
    end

    def set_more_fake_attrs
      self.fake2 = 'dos'
    end

  end


  let(:valid_work_area) do
    {
      'type' => 'polygon',
      'coordinates' => [[
        [-122.4119,37.78211],
        [-122.39285,37.79649],
        [-122.37997,37.78415],
        [-122.39817,37.77248],
        [-122.40932,37.77302],
        [-122.4119,37.78211]
      ]]
    }
  end


  context "index" do

    it "allows determining the index and type the model belongs to" do
      expect(TestModel.index).to be_a(Waistband::Index)
      expect(TestModel.index.send(:config_name)).to eql 'geo_test'
      expect(TestModel.type_name).to eql('geo')
    end

    it "allows determining the index type" do
    end

  end

  context "instantiation" do

    it "allows instantiating a model with no information" do
      thing = TestModel.new
      expect(thing).to be_a(Waistband::Model)
      expect(thing.index).to be_a(Waistband::Index)
      expect(thing.type_name).to eql('geo')
      expect(thing.work_area).to be_nil

      thing.work_area = valid_work_area

      expect(thing.work_area).to eql(valid_work_area)
    end

    it "defaults fields" do
      thing = TestModel.new
      expect(thing.important).to eql(true)
      expect(thing.shenanigans).to eql(1)
    end

  end

  context "validations" do

    it "validates a model" do
      thing = TestModel.new
      expect(thing.valid?).to eql(false)
      thing.work_area = {type: 'polygon'}
      expect(thing.valid?).to eql(true)
    end

  end

  context "callbacks" do

    it "executes callbacks" do
      thing = TestModel.new
      thing.work_area = valid_work_area
      expect(thing.valid?).to eql(true)
      expect(thing.fake1).to eql('uno')

      # not defined until after setting it
      expect{ thing.fake2 }.to raise_error(NoMethodError)

      expect(thing.save).to eql(true)

      expect(thing.fake2).to eql('dos')
    end

  end

  context "persistence" do

    it "persists an object" do
      thing = TestModel.new
      thing.work_area = valid_work_area
      expect(thing.save).to eql(true)
      expect(thing.id).to be_present
      expect(thing.id).to be_a(String)
    end

    it "doesn't persist when not valid" do
      thing = TestModel.new
      expect(thing.valid?).to eql(false)
      expect(thing.save).to eql(false)
      expect(thing.id).to eql(nil)
    end

  end

  context "reading" do

    it "allows reading a previously saved object" do
      thing = TestModel.new
      thing.work_area = valid_work_area
      expect(thing.save).to eql(true)
      saved_id = thing.id
      expect(saved_id).to be_present

      found = TestModel.find(saved_id)
      expect(found).to be_present
      expect(found).to be_a(TestModel)
      expect(found.id).to eql(saved_id)
      expect(found.work_area).to eql(valid_work_area)
    end

    it "raises an error when we cannot find an id" do
      expect{ TestModel.find('9191919191') }.to raise_error(::Waistband::Errors::Model::NotFound, "Couldn't find TestModel with 'id'=9191919191")
    end

  end

  context "searching" do

    it "allows searching for a saved object" do
      thing = TestModel.new
      thing.work_area = valid_work_area
      thing.searchable = 'hello one two three'
      expect(thing.save).to eql(true)
      saved_id = thing.id
      expect(saved_id).to be_present

      TestModel.index.refresh

      results = TestModel.search(
        query: {
          query_string: {
            query: "+searchable:hello*"
          }
        }
      )

      expect(results).to be_an(Array)
      expect(results.size).to eql(1)

      result = results.first
      expect(result).to be_present
      expect(result).to be_a(TestModel)
      expect(result.id).to eql(saved_id)
      expect(result.work_area).to eql(valid_work_area)
    end

  end

end

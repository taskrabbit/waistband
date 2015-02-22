require 'spec_helper'

describe Waistband::Model do

  class TestModel < Waistband::Model

    index_name :geo
    index_type :geo

    defaults important: true, shenanigans: 1

    validates :work_area, presence: true

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

      thing.work_area = {
        type: 'polygon',
        coordinates: [[
          [-122.41997,37.79744]
        ]]
      }

      expect(thing.work_area).to eql({
        type: 'polygon',
        coordinates: [[
          [-122.41997,37.79744]
        ]]
      })
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
  end

  context "persistance" do
  end

  context "reading" do
  end

  context "searching" do
  end

end

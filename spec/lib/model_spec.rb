require 'spec_helper'

describe "Waistband::Model" do

  describe 'without ActiveModel defined' do

    it "blows up if ActiveModel is not defined" do
      expect {
        Waistband::Model.new
      }.to raise_error(RuntimeError, "ActiveModel not defined!")
    end

  end

  describe 'with ActiveModel defined' do

    require 'active_model'

    class TestModel < Waistband::Model
      index :test_model
      columns :age, :name

      validates :age, presence: true
    end

    let(:testy) { TestModel.new(age: 32, name: 'Peter') }

    it "doesn't blow up when ActiveModel is loaded" do
      expect {
        Waistband::Model.new
      }.to_not raise_error
    end

    it "permits creating a model" do
      expect(testy.name).to eql 'Peter'
      expect(testy.age).to eql 32
      expect(testy).to be_valid

      testy.age = nil
      expect(testy).to_not be_valid
    end

    it "proxies to an index" do
      expect(testy.index).to be_a Waistband::Index
    end

    it "persists to ES" do
      expect(testy.save).to be_true
    end

  end

end


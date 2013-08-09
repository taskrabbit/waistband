require 'spec_helper'

describe Waistband::StringifiedHash do

  let(:hash) { Waistband::StringifiedHash.new }

  it "stringifies everything in a hash" do
    hash['name'] = :peter
    hash['description'] = {'full' => 'ok'}
    hash.stringify_all.should eql({'name' => 'peter', 'description' => "{\"full\"=>\"ok\"}"})
  end

  it "recurses" do
    hash['name'] = :peter
    hash['description'] = [1, 2, 3]
    hash.stringify_all.should eql({'name' => 'peter', 'description' => "[1, 2, 3]"})
  end

  it "creates a stringified array from a hash" do
    copy = Waistband::StringifiedHash.new_from({'name' => 'peter', 'description' => [1, 2, 3]})
    copy.should be_a Waistband::StringifiedHash
    copy['name'].should eql 'peter'
    copy['description'].should eql [1, 2, 3]
    copy.stringify_all.should eql({'name' => 'peter', 'description' => "[1, 2, 3]"})
  end

end

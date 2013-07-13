require 'spec_helper'

describe Waistband::StringifyAll do

  before do
    Array.send(:include, Waistband::StringifyAll::Array)
    Hash.send(:include, Waistband::StringifyAll::Hash)
  end

  it "stringifies everything in an array" do
    [1, 2, 3].stringify_all.should eql %w(1 2 3)
  end

  it "stringifies everything in a hash" do
    {'name' => :peter, 'description' => {'full' => 'ok'}}.stringify_all.should eql({'name' => 'peter', 'description' => "{\"full\"=>\"ok\"}"})
  end

  it "recurses" do
    {'name' => :peter, 'description' => [1, 2, 3]}.stringify_all.should eql({'name' => 'peter', 'description' => "[1, 2, 3]"})
  end

end

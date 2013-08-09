require 'spec_helper'

describe Waistband::StringifiedArray do

  it "stringifies everything in an array" do
    Waistband::StringifiedArray.new([1, 2, 3]).stringify_all.should eql %w(1 2 3)
  end

end

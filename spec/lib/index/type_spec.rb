require 'spec_helper'

describe "Waistband::Index - Type" do

  it "defaults to the first type we find in the mappings if possible" do
    index = Waistband::Index.new('events_no_name')
    expect(index.send(:default_type_name)).to eql 'event'
  end

  it "defaults to singular index name if no mappings" do
    index = Waistband::Index.new('no_mappings')
    expect(index.send(:default_type_name)).to eql 'no_mapping'
  end

end

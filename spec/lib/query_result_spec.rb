require 'spec_helper'

describe Waistband::QueryResult do

  let(:hit)     { {"_index"=>"search", "_type"=>"search", "_id"=>"task_14969", "_score"=>5.810753, "_source"=>{"id"=>14969, "name"=>"shopping"}} }
  let(:result)  { Waistband::QueryResult.new(hit) }

  it "allows access to inner document" do
    result.source.should  eql hit['_source']
    result._id.should      eql 'task_14969'
    result.score.should   eql 5.810753
  end

  it "provides methods for source attributes" do
    result.id.should eql 14969
    result.name.should eql 'shopping'
  end

  it "returns nil if the method missing misses" do
    result.something_else.should be_nil
  end

end

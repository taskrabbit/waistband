require 'spec_helper'

describe ::Waistband::Result do

  let(:result_hash) do
    {
      "_index" => "bus_events",
      "_type" => "bus_event",
      "_id" => "a2081c0ce39b25d50b0a4be3c116ee7f",
      "_score" => nil,
      "_source" => {
        "bus_event_type" => "task_opened",
        "timeline_event" => "true",
        "_message" => "true"
      },
      "sort" => [nil]
    }
  end

  let(:result) { ::Waistband::Result.new(result_hash) }

  it "provides accessors for all default fields" do
    expect(result._id).to eql 'a2081c0ce39b25d50b0a4be3c116ee7f'
    expect(result._score).to be_nil
    expect(result._type).to eql 'bus_event'
    expect(result._index).to eql 'bus_events'
    expect(result.sort).to eql([nil])
    expect(result._source).to eql({
      "bus_event_type" => "task_opened",
      "timeline_event" => "true",
      "_message" => "true"
    })
  end

  it "provides method missing interface for the _source hash" do
    expect(result.bus_event_type).to eql 'task_opened'
    expect(result.timeline_event).to eql 'true'
    expect(result._message).to eql 'true'
  end

end

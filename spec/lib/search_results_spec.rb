require 'spec_helper'

describe ::Waistband::SearchResults do

  let(:search_hash) do
    {
      "took" => 1,
      "timed_out" => false,
      "_shards" => {
        "total" => 12,
        "successful" => 12,
        "failed" => 0
      },
      "hits" => {
        "total" => 1,
        "max_score" => nil,
        "hits" => [{
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
        }]
      }
    }
  end

  let(:results) { ::Waistband::SearchResults.new(search_hash, page_size: 10) }

  it "provides a method interface for the results hash array" do
    expect(results.took).to eql 1
    expect(results.timed_out).to be false
    expect(results._shards).to eql({
      "total" => 12,
      "successful" => 12,
      "failed" => 0
    })
  end

  it "provides a shortcut to get the total number of hits" do
    expect(results.total_results).to eql 1
  end

  it "provides a shortcut to get the hits directly" do
    expect(results.hits).to be_an Array
    hit = results.hits.first

    expect(hit['_id']).to eql 'a2081c0ce39b25d50b0a4be3c116ee7f'
    expect(hit['_source']['bus_event_type']).to eql 'task_opened'
  end

  it "maps hits to results" do
    expect(results.results).to be_an Array

    result = results.results.first

    expect(result).to be_a ::Waistband::Result
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
    expect(result.bus_event_type).to eql 'task_opened'
    expect(result.timeline_event).to eql 'true'
    expect(result._message).to eql 'true'
  end

  describe '#paginated_hits' do

    it "provides a paginated array compatible with a readonly Kaminari array" do
      load 'active_support/concern.rb'

      expect(results.paginated_hits).to be_a ::Waistband::SearchResults::PaginatedArray
      expect(results.paginated_hits.total_pages).to eql 1
      expect(results.paginated_hits.current_page).to eql 1
      expect(results.paginated_hits.instance_variable_get('@per_page')).to eql 10
    end

  end

  describe '#paginated_results' do

    it "provides a paginated array compatible with a readonly Kaminari array" do
      load 'active_support/concern.rb'

      expect(results.paginated_results).to be_a ::Waistband::SearchResults::PaginatedArray
      expect(results.paginated_results.total_pages).to eql 1
      expect(results.paginated_results.current_page).to eql 1
      expect(results.paginated_hits.instance_variable_get('@per_page')).to eql 10
    end

  end

end

require 'spec_helper'

describe Waistband::Query do

  let(:index)     { Waistband::Index.new('search') }
  let(:geo_index) { Waistband::Index.new('geo') }

  let(:query)     { Waistband::Query.new(index) }
  let(:geo_query) { Waistband::Query.new(geo_index) }

  let(:attrs) do
    {
      'query' => {
        'bool' => {
          'must' => [
            {
              'multi_match' => {
                'query' => "shopping ikea",
                'fields' => ['name']
              },
            }
          ]
        }
      }
    }
  end

  it "correclty forms a query hash" do
    add_result!
    query.prepare(attrs)

    expect(query.instance_variable_get('@hash')).to eql(attrs)
  end

  it "finds results for a query" do
    add_result!
    query.prepare(attrs)
    json = query.send(:execute!)

    json['hits'].should be_a Hash
    json['hits']['total'].should > 0
    json['hits']['hits'].size.should eql 2

    hit = json['hits']['hits'].first

    hit['_id'].should match(/^task_.*/)
    hit['_source'].should be_a Hash
    hit['_source']['id'].should eql 123123
    hit['_source']['name'].should eql 'some shopping in ikea'
    hit['_source']['user_id'].should eql 999
    hit['_source']['description'].should eql 'i need you to pick up some stuff in ikea'
  end

  it "permits storing and fetching geo results" do
    add_geo_results!
    geo_query.prepare({
      "query" => {
        "filtered" => {
          "query" => { "match_all" => {} },
          "filter" => {
             "geo_shape" => {
               "work_area" => {
                 "relation" => "intersects",
                 "shape" => {
                   "type" => "Point",
                   "coordinates" => [-122.39455,37.7841]
                 }
               }
             }
          }
        }
      }
    })

    json = geo_query.send(:execute!)

    json['hits'].should be_a Hash
    json['hits']['total'].should eql 3
    json['hits']['hits'].size.should eql 3

    geo_query.prepare({
      "query" => {
        "filtered" => {
          "query" => { "match_all" => {} },
          "filter" => {
             "geo_shape" => {
               "work_area" => {
                 "relation" => "intersects",
                 "shape" => {
                   "type" => "Point",
                   "coordinates" => [-122.3859222222222,37.78292222222222]
                 }
               }
             }
          }
        }
      }
    })

    json = geo_query.send(:execute!)

    json['hits'].should be_a Hash
    json['hits']['total'].should eql 1
    json['hits']['hits'].size.should eql 1
  end

  def add_result!
    index.store!("task_123123", {id: 123123, name: 'some shopping in ikea',                   user_id: 999, description: 'i need you to pick up some stuff in ikea',  internal: false})
    index.store!("task_234234", {id: 234234, name: "some shopping in ikea and trader joe's",  user_id: 987, description: 'pick me up some eggs',                      internal: true})
    index.refresh
  end

  def add_geo_results!
    geo_index.store!("rabbit_1", {
      id: "rabbit_1",
      work_area: {
        type: 'polygon',
        coordinates: [[
          [-122.4119,37.78211],
          [-122.39285,37.79649],
          [-122.37997,37.78415],
          [-122.39817,37.77248],
          [-122.40932,37.77302],
          [-122.4119,37.78211]
        ]]
      }
    })

    geo_index.store!("rabbit_2", {
      id: "rabbit_2",
      work_area: {
        type: 'polygon',
        coordinates: [[
          [-122.41087,37.78822],
          [-122.43174,37.78578],
          [-122.42816,37.75938],
          [-122.38787,37.76882],
          [-122.39199,37.78584],
          [-122.41087,37.78822]
        ]]
      }
    })

    geo_index.store!("rabbit_3", {
      id: "rabbit_3",
      work_area: {
        type: 'polygon',
        coordinates: [[
          [-122.41997,37.79744],
          [-122.39576,37.79975],
          [-122.38461,37.78469],
          [-122.40294,37.77738],
          [-122.41997,37.79744]
        ]]
      }
    })

    geo_index.refresh
  end

end

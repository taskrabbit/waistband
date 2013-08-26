require 'spec_helper'
require 'active_support/core_ext/kernel/reporting'

Kernel.silence_stderr do
  require 'kaminari'
end

describe Waistband::Query do

  let(:index) { Waistband::Index.new('search') }
  let(:query) { index.query('shopping ikea') }

  describe '#execute!' do

    before { add_result! }

    it "gets results from elastic search" do
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

    it "boosts results with optional terms" do
      query = index.query('shopping ikea')
      query.add_field('name')
      query.add_optional_term('internal', 'true')

      json = query.send(:execute!)

      json['hits']['hits'].size.should eql 2

      hit = json['hits']['hits'].first

      hit['_id'].should match(/^task_.*/)
      hit['_source'].should be_a Hash
      hit['_source']['id'].should eql 234234
      hit['_source']['name'].should eql "some shopping in ikea and trader joe's"
      hit['_source']['user_id'].should eql 987
      hit['_source']['description'].should eql 'pick me up some eggs'
    end

  end

  describe '#add_sort' do

    it "adds sort field" do
      query.add_sort('created_at', 'asc')
      query.instance_variable_get('@sorts').should eql [{key: 'created_at', ord: 'asc'}]

      query.add_sort('updated_at', 'desc')
      query.instance_variable_get('@sorts').should eql [{key: 'created_at', ord: 'asc'}, {key: 'updated_at', ord: 'desc'}]
    end

  end

  describe '#add_range' do

    it "adds a range" do
      query.add_range('task_id', 5, 10)
      query.instance_variable_get('@ranges').should eql [{field: 'task_id', min: 5, max: 10}]
    end

  end

  describe '#add_field' do

    it "adds field" do
      query.add_field('name')
      query.instance_variable_get('@fields').should eql ['name']
    end

    it "adds multiple fields at once" do
      query.add_field('name', 'description')
      query.instance_variable_get('@fields').should eql ['name', 'description']
    end

  end

  describe '#add_term' do

    it "adds the term on the key" do
      query.add_term('metro', 'boston')
      query.instance_variable_get('@terms')['metro'][:keywords].should eql ['boston']
    end

    it "adds several terms on multiple words" do
      query.add_term('metro', 'sf bay area')
      query.instance_variable_get('@terms')['metro'][:keywords].should eql ['sf', 'bay', 'area']
    end

  end

  describe '#add_optional_term' do

    it "adds the term on the key" do
      query.add_optional_term('metro', 'boston')
      query.instance_variable_get('@optional_terms')['metro'][:keywords].should eql ['boston']
    end

    it "adds several terms on multiple words" do
      query.add_optional_term('metro', 'sf bay area')
      query.instance_variable_get('@optional_terms')['metro'][:keywords].should eql ['sf', 'bay', 'area']
    end

  end

  describe '#terms' do

    it "builds an array of all terms" do
      query.add_term('metro', 'sf bay area')
      query.send(:terms).should eql([
        {
          terms: {
            metro: ['sf', 'bay', 'area']
          }
        }
      ])
    end

    it "builds an array of single terms" do
      query.add_term('metro', 'boston')
      query.send(:terms).should eql([
        {
          terms: {
            metro: ['boston']
          }
        }
      ])
    end

    it "constructs correctly with multiple terms" do
      query.add_term('metro', 'sf bay area')
      query.add_term('geography', 'San Francisco')
      query.send(:terms).should eql([
        {
          terms: {
            metro: ["sf", "bay", "area"]}
          },
          {
            terms: {
              geography: ["San", "Francisco"]
            }
          }
      ])
    end

  end

  describe '#must_to_hash' do

    it "creates an array of the must of the query" do
      query.add_term('metro', 'sf bay area')
      query.add_field('name')
      query.send(:must_to_hash).should eql([
        {
          multi_match: {
            query: "shopping ikea",
            fields: ['name']
          }
        },
        {
          terms: {
            metro: ["sf", "bay", "area"]
          }
        }
      ])
    end

  end

  describe '#from' do

    it "returns 0 when page is 1" do
      Waistband::Query.new('search', 'shopping ikea', page: 1, page_size: 20).send(:from).should eql 0
    end

    it "returns 20 when page is 2 and page_size is 20" do
      Waistband::Query.new('search', 'shopping ikea', page: 2, page_size: 20).send(:from).should eql 20
    end

    it "returns 30 when page is 4 and page_size is 10" do
      Waistband::Query.new('search', 'shopping ikea', page: 4, page_size: 10).send(:from).should eql 30
    end

    it "returns 10 when page is 2 and page_size is 10" do
      Waistband::Query.new('search', 'shopping ikea', page: 2, page_size: 10).send(:from).should eql 10
    end

  end

  describe '#to_hash' do

    it "constructs the query's json" do
      query.add_term('metro', 'sf bay area')
      query.add_field('name')
      query.add_sort('created_at', 'desc')
      query.add_range('task_id', 1, 10)

      query.send(:to_hash).should eql({
        query: {
          bool: {
            must: [
              {
                multi_match: {
                  query: "shopping ikea",
                  fields: ['name']
                },
              },
              {
                range: {
                  'task_id' => {
                    lte: 10,
                    gte: 1
                  }
                }
              },
              {
                terms: {
                  metro: ["sf","bay","area"]
                }
              }
            ],
            must_not: [],
            should: []
          }
        },
        from: 0,
        size: 20,
        sort: [
          {'created_at' => 'desc'},
          '_score'
        ]
      })
    end

    it 'constructs the query with several terms' do
      query.add_term('metro', 'sf bay area')
      query.add_term('geography', 'San Francisco')
      query.add_optional_term('internal', 'true')
      query.add_field('name')
      query.add_field('description')
      
      query.send(:to_hash).should eql({
        query: {
          bool: {
            must: [
              {
                multi_match: {
                  query: "shopping ikea",
                  fields: ['name', 'description']
                }
              },
              {
                terms: {
                  metro: ["sf", "bay", "area"]
                }
              },
              {
                terms: {
                  geography: ["San", "Francisco"]
                }
              }
            ],
            must_not: [],
            should: [
              {
                terms: {
                  internal: ['true']
                }
              }
            ]
          }
        },
        from: 0,
        size: 20,
        sort: ['_score']
      })
    end

  end

  describe '#results' do

    it "returns a QueryResult array" do
      add_result!

      query.results.first.should be_a Waistband::QueryResult
    end

  end

  describe '#paginated_results' do

    it "returns a kaminari paginated array" do
      add_result!

      query.paginated_results.should be_an Array
    end

  end

  def add_result!
    index.store!("task_123123", {id: 123123, name: 'some shopping in ikea',                   user_id: 999, description: 'i need you to pick up some stuff in ikea',  internal: false})
    index.store!("task_234234", {id: 234234, name: "some shopping in ikea and trader joe's",  user_id: 987, description: 'pick me up some eggs',                      internal: true})
    index.refresh

    query.add_field('name')
  end

end

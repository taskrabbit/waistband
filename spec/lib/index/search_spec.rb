require 'spec_helper'

describe "Waistband::Index -- Search" do

  let(:index)   { Waistband::Index.new('events') }

  it "proxies to the client's search" do
    result = index.search({})
    expect(result).to be_a Waistband::SearchResults
    expect(result.took).to be_present
    expect(result.hits).to be_an Array
  end

  describe 'paginating search results' do

    it "permits paginating" do
      results = index.search(page: 5, page_size: 15)
      expect(results.instance_variable_get('@page')).to eql 5
      expect(results.instance_variable_get('@page_size')).to eql 15
    end

    it "permits passing in page_size without page" do
      results = index.search(page_size: 999)
      expect(results.instance_variable_get('@page')).to eql 1
      expect(results.instance_variable_get('@page_size')).to eql 999
    end

    describe 'with results' do

      before do
        index.delete
        index.create
        index.refresh

        index.save('__test_write1',  {'data' => 'index_1'})
        index.save('__test_write2',  {'data' => 'index_2'})
        index.save('__test_write3',  {'data' => 'index_3'})
        index.save('__test_write4',  {'data' => 'index_4'})
        index.refresh
      end

      it "respects paginating when fetching hits" do
        query = index.search(page: 1, page_size: 10)
        expect(query.hits.size).to eql 4

        query = index.search(page: 2, page_size: 10)
        expect(query.hits.size).to eql 0

        query = index.search(page: 1, page_size: 2)
        expect(query.hits.size).to eql 2
      end

      it "paginates when not passing in a page number" do
        query = index.search(page_size: 10)
        expect(query.hits.size).to eql 4

        query = index.search(page_size: 2)
        expect(query.hits.size).to eql 2
      end

      it 'returns results beyond page 1 (does not double scope)' do
        query = index.search(page_size: 2, page: 1)
        hits1 = query.hits
        expect(hits1.size).to eql 2

        query = index.search(page_size: 2, page: 2)
        hits2 = query.hits
        expect(hits2.size).to eql 2

        expect(hits1 & hits2).to be_empty
      end

    end

  end

end

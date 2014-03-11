module Waistband
  class SearchResults

    def initialize(search_hash)
      @search_hash = search_hash
    end

    def hits
      raise ::Waistband::Errors::NoSearchHits.new("No search hits!") unless @search_hash['hits']
      @search_hash['hits']['hits']
    end

    def total_results
      raise ::Waistband::Errors::NoSearchHits.new("No search hits!") unless @search_hash['hits']
      @search_hash['hits']['total']
    end

  end
end

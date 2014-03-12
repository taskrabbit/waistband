require 'waistband/result'

module Waistband
  class SearchResults

    DEFAULT_PAGE_SIZE = 20

    def initialize(search_hash, options = {})
      @page = options[:page] || 1
      @page_size = options[:page_size] || DEFAULT_PAGE_SIZE
      @search_hash = search_hash
    end

    def hits
      raise ::Waistband::Errors::NoSearchHits.new("No search hits!") unless @search_hash['hits']
      @search_hash['hits']['hits']
    end

    def results
      raise ::Waistband::Errors::NoSearchHits.new("No search hits!") unless @search_hash['hits']

      hits.map do |hit|
        ::Waistband::Result.new(hit)
      end
    end

    def paginated_hits
      raise "Kaminari gem not found for pagination" unless defined?(Kaminari)
      Kaminari.paginate_array(hits, total_count: total_results).page(@page).per(@page_size)
    end

    def paginated_results
      raise "Kaminari gem not found for pagination" unless defined?(Kaminari)
      Kaminari.paginate_array(results, total_count: total_results).page(@page).per(@page_size)
    end

    def total_results
      raise ::Waistband::Errors::NoSearchHits.new("No search hits!") unless @search_hash['hits']
      @search_hash['hits']['total']
    end

    def method_missing(method_name, *args, &block)
      return @search_hash[method_name.to_s] if @search_hash.keys.include?(method_name.to_s)
      super
    end

    def respond_to_missing?(method_name, include_private = false)
      return true if @search_hash.keys.include?(method_name.to_s)
      super
    end

  end
end

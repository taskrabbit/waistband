require 'waistband/result'

module Waistband
  class SearchResults

    class PaginatedArray < Array

      attr_reader :total_count, :per_page, :num_pages, :total_pages, :current_page

      def initialize(arr, options)
        @current_page = (options[:current_page] || 1).to_i
        @total_count = (options[:total_count] || arr.length).to_i
        @per_page = (options[:per_page] || ::Waistband::SearchResults::DEFAULT_PAGE_SIZE).to_i
        @num_pages = @total_pages = (options[:num_pages] || (@total_count.to_f / @per_page).ceil)
        super(arr)
      end

    end

    DEFAULT_PAGE_SIZE = 20

    def initialize(search_hash, options = {})
      @page = (options[:page] || 1).to_i
      @page_size = (options[:page_size] || DEFAULT_PAGE_SIZE).to_i
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
      ::Waistband::SearchResults::PaginatedArray.new(hits, current_page: @page, page_size: @page_size, total_count: total_results)
    end

    def paginated_results
      ::Waistband::SearchResults::PaginatedArray.new(results, current_page: @page, page_size: @page_size, total_count: total_results)
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

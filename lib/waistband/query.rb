require 'active_support/core_ext/hash/indifferent_access'

module Waistband
  class Query

    attr_accessor :page, :page_size

    def initialize(index, options = {})
      @index      = index
      @page       = (options[:page] || 1).to_i
      @page_size  = (options[:page_size] || 20).to_i
      prepare
    end

    def prepare(hash = {})
      @hash = hash.with_indifferent_access
      self
    end

    def paginated_results
      return Kaminari.paginate_array(results, total_count: total_results).page(@page).per(@page_size) if defined?(Kaminari)
      raise "Please include the `kaminari` gem to use this method!"
    end

    def results
      hits.map do |hit|
        Waistband::QueryResult.new(hit)
      end
    end

    def hits
      execute!['hits']['hits'] rescue []
    end

    def total_results
      execute!['hits']['total'] rescue 0
    end

    private

      def to_hash
        @hash[:from] = from       unless @hash[:from]
        @hash[:size] = @page_size unless @hash[:size]

        @hash
      end

      def url
        @index.search_url
      end

      def execute!
        JSON.parse(RestClient::Request.execute(method: :get, url: url, payload: to_hash.to_json))
      end

      def from
        @page_size * (@page - 1)
      end

    # /private

  end
end

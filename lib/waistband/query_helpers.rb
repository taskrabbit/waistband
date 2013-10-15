module Waistband
  module QueryHelpers

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

      def url
        index.search_url
      end

      def index
        Waistband::Index.new(@index)
      end

      def execute!
        JSON.parse(RestClient.post(url, to_hash.to_json))
      end

      def from
        @page_size * (@page - 1)
      end

    # /private

  end
end

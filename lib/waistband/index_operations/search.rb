module Waistband
  module IndexOperations
    module Search

      def search(body_hash)
        page, page_size = get_page_info body_hash
        body_hash       = parse_search_body(body_hash)
        search_hash     = {index: config_name, body: body_hash}

        search_hash[:from] = body_hash[:from] if body_hash[:from]
        search_hash[:size] = body_hash[:size] if body_hash[:size]

        search_hash = client.search(search_hash)

        ::Waistband::SearchResults.new(search_hash, page: page, page_size: page_size)
      end

      private

        def parse_search_body(body_hash)
          body_hash = body_hash.with_indifferent_access

          page = body_hash.delete(:page)
          page_size = body_hash.delete(:page_size)

          if page || page_size
            page ||= 1
            page = page.to_i
            page_size ||= 20
            body_hash[:from] = page_size * (page - 1) unless body_hash[:from]
            body_hash[:size] = page_size              unless body_hash[:size]
          end

          body_hash
        end

        def get_page_info(body_hash)
          page = body_hash[:page]
          page_size = body_hash[:page_size]
          [page, page_size]
        end

    end
  end
end

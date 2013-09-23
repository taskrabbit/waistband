require 'json'
require 'rest-client'
require 'active_support/core_ext/object/blank'
require 'kaminari/models/array_extension' if defined?(Kaminari)

module Waistband
  class Query

    attr_accessor :page, :page_size

    def initialize(index, search_term, options = {})
      @index          = index
      @search_term    = search_term
      @wildcards      = []
      @fields         = []
      @ranges         = []
      @sorts          = []
      @terms          = {}
      @exclude_terms  = {}
      @optional_terms = {}
      @page           = (options[:page] || 1).to_i
      @page_size      = (options[:page_size] || 20).to_i
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

    def add_match(field)
      @match = field
    end

    def add_fields(*fields)
      @fields |= fields
      @fields = @fields.compact.uniq
    end
    alias :add_field :add_fields

    def add_wildcard(wildcard, value)
      @wildcards << {
        wildcard: wildcard,
        value: value
      }
    end

    def add_range(field, min, max)
      @ranges << {
        field: field,
        min: min,
        max: max
      }
    end

    def add_terms(key, words)
      @terms[key] ||= {
        keywords: []
      }
      @terms[key][:keywords] += prep_words_uniquely(words)
    end
    alias :add_term :add_terms

    def add_exclude_terms(key, words)
      @exclude_terms[key] ||= {
        keywords: []
      }
      @exclude_terms[key][:keywords] += prep_words_uniquely(words)
    end
    alias :add_exclude_term :add_exclude_terms

    def add_optional_terms(key, words)
      @optional_terms[key] ||= {
        keywords: []
      }
      @optional_terms[key][:keywords] += prep_words_uniquely(words)
    end
    alias :add_optional_term :add_optional_terms

    def add_sort(key, ord)
      @sorts << {
        key: key,
        ord: ord
      }
    end

    def add_random_sort
      @random_sort = {
        _script:  {
          script:   "Math.random()",
          type:     :number,
          params:   {},
          order:    :asc
        }
      }
    end

    private

      def url
        index.search_url
      end

      def index
        Waistband::Index.new(@index)
      end

      def execute!
        @executed ||= JSON.parse(RestClient.post(url, to_hash.to_json))
      end

      def to_hash
        {
          query: {
            bool: {
              must:     must_to_hash,
              must_not: must_not_to_hash,
              should:   should_to_hash
            }
          },
          from: from,
          size: @page_size,
          sort: sort_to_hash
        }
      end

      def sort_to_hash
        return @random_sort if @random_sort

        sort = []

        @sorts.each do |s|
          sort << {s[:key] => s[:ord]}
        end

        sort << '_score'

        sort
      end

      def must_to_hash
        must = []

        must << {
          multi_match: {
            query: @search_term,
            fields: @fields
          }
        } if @fields.any?

        @wildcards.each do |wc|
          must << {
            wildcard: {
              wc[:wildcard] => wc[:value]
            }
          }
        end

        @ranges.each do |range|
          must << {
            range: {
              range[:field] => {
                lte: range[:max],
                gte: range[:min],
              }
            }
          }
        end

        must << {
          match: {
            @match => @search_term
          }
        } if @match.present?

        prep_term_hash(@terms).each do |term|
          must << term
        end

        must
      end

      def must_not_to_hash
        prep_term_hash(@exclude_terms).map { |term| term }
      end

      def should_to_hash
        prep_term_hash(@optional_terms).map { |term| term }
      end

      def prep_term_hash(terms)
        terms.map do |key, term|
          {
            terms: {
              key.to_sym => term[:keywords]
            }
          }
        end
      end

      def from
        @page_size * (@page - 1)
      end

      def prep_words_uniquely(val)
        val.to_s.gsub(/ +/, ' ').strip.split(' ').uniq
      end

    # /private

  end
end

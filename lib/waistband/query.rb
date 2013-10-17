require 'active_support/core_ext/hash/indifferent_access'

module Waistband
  class Query

    include ::Waistband::QueryHelpers

    attr_accessor :page, :page_size

    def initialize(index, options = {})
      @index      = index
      @page       = (options[:page] || 1).to_i
      @page_size  = (options[:page_size] || 20).to_i
    end

    def prepare(hash)
      @hash = hash.with_indifferent_access
      self
    end

    private

      def to_hash
        raise "No query has been prepared yet!" unless @hash

        @hash[:from] = from       unless @hash[:from]
        @hash[:size] = @page_size unless @hash[:size]

        @hash
      end

    # /private

  end
end

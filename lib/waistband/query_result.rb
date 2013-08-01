require 'active_support/core_ext/hash/keys'

module Waistband
  class QueryResult

    attr_reader :source, :_id, :score

    def initialize(row)
      @source = row['_source'].stringify_keys
      @_id     = row['_id']
      @score  = row['_score']
    end

    def method_missing(method_name, *args, &block)
      @source[method_name.to_s]
    end

    def respond_to_missing?(method_name, include_private = false)
      return true if @source.keys.map(&:to_s).include?(method_name.to_s)
      super
    end

  end
end

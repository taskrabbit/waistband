module Waistband
  class Result

    def initialize(result_hash)
      @result_hash = result_hash
    end

    def method_missing(method_name, *args, &block)
      return @result_hash[method_name.to_s] if @result_hash.keys.include?(method_name.to_s)
      return @result_hash['_source'][method_name.to_s] if @result_hash['_source'] && @result_hash['_source'].keys.include?(method_name.to_s)
      nil
    end

    def respond_to_missing?(method_name, include_private = false)
      return true if @result_hash.keys.include?(method_name.to_s)
      super
    end

  end
end

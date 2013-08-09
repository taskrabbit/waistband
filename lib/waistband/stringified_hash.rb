module Waistband
  class StringifiedHash < Hash

    class << self

      def new_from(original)
        copy = new
        original.each do |k, v|
          copy[k] = v
        end
        copy
      end

    end

    def stringify_all
      stringified = {}

      each do |key, val|
        if val.respond_to?(:to_s)
          stringified[key] = val.to_s
        else
          stringified[key] = val
        end
      end

      stringified
    end

  end
end

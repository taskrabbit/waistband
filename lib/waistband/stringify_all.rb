module Waistband

  module StringifyAll

    module Array

      def stringify_all
        self.map do |val|
          if val.respond_to?(:to_s)
            val.to_s
          else
            val
          end
        end
      end

    end

    module Hash

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

end

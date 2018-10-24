module Suspenders
  class StringifiedArray < Array

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
end

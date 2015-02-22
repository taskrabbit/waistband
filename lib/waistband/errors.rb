module Waistband
  module Errors

    module Permissions
      class Create < StandardError; end
      class Delete < StandardError; end
      class Destroy < StandardError; end
      class Read < StandardError; end
      class Write < StandardError; end
    end

    class IndexExists < StandardError; end
    class IndexNotFound < StandardError; end
    class NoSearchHits < StandardError; end
    class UnableToSave < StandardError; end

  end
end

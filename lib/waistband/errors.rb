module Waistband
  module Errors

    module Permissions
      class PermissionError < StandardError; end

      class Create < PermissionError; end
      class DeleteIndex < PermissionError; end
      class Destroy < PermissionError; end
      class Read < PermissionError; end
      class Write < PermissionError; end
    end

    module Model
      class UnableToSave < StandardError; end
      class NotFound < StandardError; end
    end

    class IndexExists < StandardError; end
    class IndexNotFound < StandardError; end
    class NoSearchHits < StandardError; end
    class UnableToSave < StandardError; end

  end
end

module Suspenders
  module Errors

    module Permissions
      class PermissionError < StandardError; end

      class Create < PermissionError; end
      class DeleteIndex < PermissionError; end
      class Destroy < PermissionError; end
      class Read < PermissionError; end
      class Write < PermissionError; end
    end

    class IndexExists < StandardError; end
    class IndexNotFound < StandardError; end
    class NoSearchHits < StandardError; end
    class UnableToSave < StandardError; end

  end
end

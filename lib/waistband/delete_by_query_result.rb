# frozen_string_literal: true

module Waistband
  class DeleteByQueryResult
    attr_reader :deleted, :full_response

    def initialize(response)
      @full_response = response
      @deleted = response['deleted']
    end
  end
end

class IndexHelper

  INDEXES = %w(events search)

  class << self

    def destroy_all!
      IndexHelper::INDEXES.each do |index|
        Waistband::Index.new(index).destroy!
      end
    end

    def create_all!
      IndexHelper::INDEXES.each do |index|
        Waistband::Index.new(index).create!
      end
    end

  end

end

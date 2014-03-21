class IndexHelper

  INDEXES = %w(events search geo tasks_opened tasks_closed)

  class << self

    def delete_all
      IndexHelper::INDEXES.each do |index|
        Waistband::Index.new(index).delete
      end

      Waistband::Index.new('events', subs: %w(2013 01)).delete
    end

    def create_all
      IndexHelper::INDEXES.each do |index|
        Waistband::Index.new(index).create
      end

      Waistband::Index.new('events', subs: %w(2013 01)).create
    end

  end

end

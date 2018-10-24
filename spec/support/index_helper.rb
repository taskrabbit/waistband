class IndexHelper

  INDEXES = %w(events search geo)

  class << self

    def delete_all
      IndexHelper::INDEXES.each do |index|
        Suspenders::Index.new(index).delete
      end

      Suspenders::Index.new('events', subs: %w(2013 01)).delete
    end

    def create_all
      IndexHelper::INDEXES.each do |index|
        Suspenders::Index.new(index).create
      end

      Suspenders::Index.new('events', subs: %w(2013 01)).create
    end

  end

end

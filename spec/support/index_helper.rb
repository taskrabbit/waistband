class IndexHelper

  INDEXES = %w(events search geo)

  class << self

    def destroy_all
      IndexHelper::INDEXES.each do |index|
        Waistband::Index.new(index).destroy
      end

      Waistband::Index.new('events', subs: %w(2013 01)).destroy
    end

    def create_all
      IndexHelper::INDEXES.each do |index|
        Waistband::Index.new(index).create
      end

      Waistband::Index.new('events', subs: %w(2013 01)).create
    end

  end

end

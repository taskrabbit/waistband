module Waistband
  class Index

    def initialize(index)
      @index        = index
      @index_name   = config['name']
      @stringify    = config['stringify']
    end

    # create the index
    def create!
      connection.create! @index
    end

    # destroy the index
    def destroy!
      connection.destroy! @index
    end

    def update_settings!
      connection.update_settings! @index
    end

    # refresh the index
    def refresh
      connection.refresh @index
    end

    def store!(key, data)
      # map everything to strings
      if @stringify
        original_data = data

        if data.is_a? Array
          data = ::Waistband::StringifiedArray.new data
        elsif data.is_a? Hash
          data = ::Waistband::StringifiedHash.new_from data
        end

        data = data.stringify_all if data.respond_to? :stringify_all
      end

      result  = connection.put @index, key, data
      data    = original_data if @stringify

      result
    end

    def delete!(key)
      connection.delete! @index, key
    end

    def read(key)
      connection.read @index, key
    end

    def query(term, options = {})
      ::Waistband::Query.new @index, term, options
    end

    def search_url
      connection.search_url_for_index @index
    end

    private

      def connection
        ::Waistband::Connection.new
      end

      def config
        Waistband.config.index @index
      end

    # /private

  end
end

require 'json'
require 'rest-client'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/hash/except'

module Waistband
  class Index

    MAX_RETRIES = 10

    def initialize(index)
      @index        = index
      @index_name   = config['name']
      @stringify    = config['stringify']
      @retries      = 0
    end

    # create the index
    def create!
      RestClient.post(url, index_json)
    rescue RestClient::BadRequest => ex
      nil
    end

    # destroy the index
    def destroy!
      RestClient.delete(url)
    rescue RestClient::ResourceNotFound => ex
      nil
    end

    def update_settings!
      RestClient.put("#{url}/_settings", settings_json)
    end

    # refresh the index
    def refresh
      RestClient.post("#{url}/_refresh", {})
    end

    def store!(key, data)
      # map everything to strings
      data = data.stringify_all if @stringify && data.respond_to?(:stringify_all)

      RestClient.put(url_for_key(key), data.to_json)
    end

    def delete!(key)
      RestClient.delete(url_for_key(key))
    end

    def read(key)
      fetched = RestClient.get(url_for_key(key))
      JSON.parse(fetched)['_source'].with_indifferent_access
    rescue RestClient::ResourceNotFound => ex
      nil
    end

    def query(term, options = {})
      Waistband::Query.new(@index_name, term, options)
    end

    private

      def url_for_key(key)
        "#{url}/#{@index.singularize}/#{key}"
      end

      def settings_json
        @settings_json ||= begin
          settings = config['settings']['index'].except('number_of_shards')
          {index: settings}.to_json
        end
      end

      def index_json
        @index_json ||= config.except('name', 'stringify').to_json
      end

      def config
        @config ||= Waistband.config.index(@index)
      end

      def url
        "#{Waistband.config.hostname}/#{@index_name}"
      end

    # /private

  end
end

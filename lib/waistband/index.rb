require 'json'
require 'rest-client'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/hash/indifferent_access'

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

      with_retry do
        RestClient.put(url_for_key(key), data.to_json)
      end
    end

    def delete!(key)
      with_retry do
        RestClient.delete(url_for_key(key))
      end
    end

    def read(key)
      with_retry do
        fetched = RestClient.get(url_for_key(key))
        JSON.parse(fetched)['_source'].with_indifferent_access
      end
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

      def with_retry
        begin
          yield
        rescue RestClient::InternalServerError => ex
          if no_shard_error?(ex)
            retry
          else
            raise ex
          end
        end
      end

      def no_shard_error?(ex)
        if tr_config.elastic_search_retry && @retries < MAX_RETRIES && ex.respond_to?(:http_body) && ex.http_body.match("NoShardAvailableActionException")
          @retries += 1
          true
        else
          false
        end
      end

    # /private

  end
end

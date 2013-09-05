require 'json'
require 'rest-client'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/hash/indifferent_access'

module Waistband
  class Connection

    class NoMoreServers < Exception; end

    def initialize(options = {})
      @blacklist      = []
      @retry_on_fail  = options.fetch :retry_on_fail, true
      @orderly        = options.fetch :orderly, false
      pick_server
    end

    def create!(index)
      execute! 'post', relative_url_for_index(index), index_json(index)
    rescue RestClient::BadRequest => ex
      nil
    end

    def destroy!(index)
      execute! 'delete', relative_url_for_index(index)
    rescue RestClient::ResourceNotFound => ex
      nil
    end

    def update_settings!(index)
      execute! 'put', "#{relative_url_for_index(index)}/_settings", settings_json(index)
    end

    def refresh(index)
      execute! 'post', "#{relative_url_for_index(index)}/_refresh", {}
    end

    def read(index, key)
      fetched = execute! 'get', relative_url_for_key(index, key)
      JSON.parse(fetched)['_source'].with_indifferent_access
    rescue RestClient::ResourceNotFound => ex
      nil
    end

    def put(index, key, data)
      execute! 'put', relative_url_for_key(index, key), data.to_json
    end

    def delete!(index, key)
      execute! 'delete', relative_url_for_key(index, key)
    end

    def search_url_for_index(index)
      "#{url}/#{relative_url_for_index(index)}/_search"
    end

    private

      def execute!(method_name, relative_url, data = nil)
        full_url = "#{url}/#{relative_url}"

        Timeout::timeout ::Waistband.config.timeout do
          RestClient.send method_name, full_url, data
        end
      rescue Timeout::Error, Errno::EHOSTUNREACH, Errno::ECONNREFUSED => e
        # something's wrong, lets blacklist this sucker
        blacklist! @server
        retry if @retry_on_fail
      end

      def relative_url_for_key(index, key)
        "#{relative_url_for_index(index)}/#{index.singularize}/#{key}"
      end

      def relative_url_for_index(index)
        "#{index_name(index)}"
      end

      def url
        "#{@server['host']}:#{@server['port']}"
      end

      def index_name(index)
        config(index)['name']
      end

      def index_json(index)
        config(index).except('name', 'stringify').to_json
      end

      def settings_json(index)
        settings = config(index)['settings']['index'].except('number_of_shards')
        {index: settings}.to_json
      end

      def config(index)
        Waistband.config.index(index)
      end

      def blacklist!(server)
        @blacklist << server['_id'] unless @blacklist.include? server['_id']
        @blacklist

        pick_server
      end

      def pick_server
        @server = next_server

        unless @server
          raise ::Waistband::Connection::NoMoreServers.new "No available servers remain"
        end

        @server
      end

      def next_server
        return available_servers.first if @orderly
        available_servers.sample
      end

      def available_servers
        ::Waistband.config.servers.reject {|server| @blacklist.include? server['_id']}
      end

    # /private

  end
end

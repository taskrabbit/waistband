require 'json'
require 'rest-client'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/hash/indifferent_access'

module Waistband
  class Connection

    ##########
    # Errors #
    ##########

    module Error

      class Resquest < Exception
        attr_accessor :result, :kind

        def index_already_exists?
          !!message.match("IndexAlreadyExistsException")
        end

        def alias_with_name_exists?
          !!message.match("InvalidIndexNameException") && !!message.match("an alias with the same name already exists")
        end

        def index_missing?
          !!message.match("IndexMissingException")
        end

        def key_missing?
          !!message.match("KeyMissing") || kind == 'KeyMissing'
        end

        def alias_not_ok?
          !!message.match("AliasNotOk")
        end
      end

      class NoMoreServers < Exception; end

    end

    ####################
    # Instance methods #
    ####################

    def initialize(index, options = {})
      @index          = index
      @blacklist      = []
      @retry_on_fail  = options.fetch :retry_on_fail, true
      @orderly        = options.fetch :orderly, false
      pick_server
    end

    def mapping!
      execute! 'get', "#{@index.config_name}/_mapping"
    end

    def mapping
      mapping!
    rescue Waistband::Connection::Error::Resquest => ex
      raise ex unless ex.index_missing?
    end

    def exists?
      !!mapping.present?
    end

    def create!
      execute! 'post', @index.config_name, @index.config_json
    end

    def create
      create!
    rescue Waistband::Connection::Error::Resquest => ex
      raise ex if !ex.index_already_exists? && ! ex.alias_with_name_exists?
    end

    def destroy
      destroy!
    rescue ::Waistband::Connection::Error::Resquest => ex
      raise ex unless ex.index_missing?
    end

    def destroy!
      execute! 'delete', @index.config_name
    end

    def update_settings!
      execute! 'put', "#{@index.config_name}/_settings", settings_json
    end

    def update_settings
      update_settings!
    rescue ::Waistband::Connection::Error::Resquest => ex
      raise ex unless ex.index_missing?
    end

    def refresh!
      execute! 'post', "#{@index.config_name}/_refresh", {}
    end

    def refresh
      refresh!
    rescue ::Waistband::Connection::Error::Resquest => ex
      raise ex unless ex.index_missing?
    end

    def alias!(alias_name)
      alias_name = full_alias_name alias_name
      fetched = execute! 'put', "#{@index.config_name}/_alias/#{alias_name}"
      parsed = JSON.parse(fetched)

      error_with('Alias not OK', result: parsed, kind: 'AliasNotOk') unless parsed.keys.include?('ok') && parsed['ok'] == true

      true
    end

    def alias(alias_name)
      alias! alias_name
    rescue ::Waistband::Connection::Error::Resquest => ex
      raise ex unless ex.alias_not_ok?
    end

    def fetch_alias(alias_name)
      alias_name = full_alias_name alias_name
      fetched = execute! 'get', "#{@index.config_name}/_alias/#{alias_name}"
      JSON.parse(fetched)
    end

    def full_alias_name(alias_name)
      name = alias_name
      name << "_#{@index.env}" unless @index.custom_name?
      name
    end

    def read!(key)
      fetched = execute! 'get', relative_url_for_key(key)
      parsed = JSON.parse(fetched)

      error_with('Key not found', result: parsed, kind: 'KeyMissing') if parsed['exists'] == false

      parsed['_source'].with_indifferent_access
    end

    def read(key)
      read! key
    rescue ::Waistband::Connection::Error::Resquest => ex
      raise ex unless ex.key_missing?
    end

    def put(key, data)
      execute! 'put', relative_url_for_key(key), data.to_json
    end

    def delete!(key)
      fetched = execute! 'delete', relative_url_for_key(key)
      parsed = JSON.parse(fetched)

      error_with('Key not found', result: parsed, kind: 'KeyMissing') if parsed['found'] == false

      true
    end

    def delete(key)
      delete! key
    rescue ::Waistband::Connection::Error::Resquest => ex
      raise ex unless ex.key_missing?
    end

    def search_url
      "#{url}/#{@index.config_name}/_search"
    end

    private

      def execute!(method_name, relative_url, data = nil)
        full_url = "#{url}/#{relative_url}"

        Timeout::timeout ::Waistband.config.timeout do
          RestClient.send method_name, full_url, data do |response, request, result|
            response_hash = JSON.parse(response)

            if msg = response_hash['error']
              error_with(msg, result: result, kind: msg.split('[').first)
            end

            response
          end
        end
      rescue Timeout::Error, Errno::EHOSTUNREACH, Errno::ECONNREFUSED, Errno::ECONNRESET
        # something's wrong, lets blacklist this sucker
        blacklist! @server
        retry if @retry_on_fail
      end

      def relative_url_for_key(key)
        "#{@index.config_name}/#{@index.base_name.singularize}/#{key}"
      end

      def url
        "#{@server['host']}:#{@server['port']}"
      end

      def index_json
        @index.config.except('name', 'stringify').to_json
      end

      def settings_json
        settings = @index.config['settings']['index'].except('number_of_shards')
        {index: settings}.to_json
      end

      def blacklist!(server)
        @blacklist << server['_id'] unless @blacklist.include? server['_id']
        @blacklist

        pick_server
      end

      def pick_server
        @server = next_server

        unless @server
          raise ::Waistband::Connection::Error::NoMoreServers.new "No available servers remain"
        end

        @server
      end

      def next_server
        return available_servers.first if @orderly
        available_servers.sample
      end

      def error_with(msg, options = {})
        exception = ::Waistband::Connection::Error::Resquest.new(msg)
        exception.result = options[:result]
        exception.kind = options[:kind]
        raise exception
      end

      def available_servers
        ::Waistband.config.servers.reject {|server| @blacklist.include? server['_id']}
      end

    # /private

  end
end

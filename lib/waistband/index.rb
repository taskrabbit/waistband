require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/array/extract_options'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/try'
require 'elasticsearch'

require 'waistband/index_operations/bulk'
require 'waistband/index_operations/crud'
require 'waistband/index_operations/search'
require 'waistband/index_operations/settings'

module Waistband
  class Index

    include ::Waistband::IndexOperations::Bulk
    include ::Waistband::IndexOperations::Crud
    include ::Waistband::IndexOperations::Search
    include ::Waistband::IndexOperations::Settings

    def initialize(index_name, options = {})
      options = options.stringify_keys

      @index_name = index_name
      @stringify  = config['stringify']
      @log_level  = config['log_level']

      # subindexes checks
      if options['version'].present?
        # version
        @version  = options['version']
        @subs     = ['version', @version]
      elsif options['subs'].present?
        # subs
        @subs = [options['subs']] if options['subs'].present?
        @subs = @subs.flatten     if @subs.is_a?(Array)
      end

    end

    def exists?
      client.indices.exists index: config_name
    end

    def refresh
      client.indices.refresh index: config_name
    end

    def alias(alias_name)
      alias_name = full_alias_name alias_name
      client.indices.put_alias(
        index: config_name,
        name: alias_name
      )
    end

    def alias_exists?(alias_name)
      alias_name = full_alias_name alias_name
      client.indices.exists_alias(
        index: config_name,
        name: alias_name
      )
    end

    def config
      ::Waistband.config.index @index_name
    end

    def client
      @client ||= begin

        _client = if client_config_hash
          ::Waistband::Client.from_config(client_config_hash)
        else
          ::Waistband.config.client
        end

        if @log_level && Waistband.config.logger
          _client.transport.logger       = Waistband.config.logger
          _client.transport.logger.level = @log_level
        end

        _client

      end
    end

    private

      def infer_type(body_hash)
        body_hash.delete(:_type) || body_hash.delete('_type') || default_type_name
      end

      def log_warning(msg)
        return unless logger

        logger.warn "[WAISTBAND :: WARNING] #{msg}"
      end

      def logger
        client.transport.logger
      end

      def client_config_hash
        config['connection']
      end

      def full_alias_name(alias_name)
        unless custom_name?
          "#{alias_name}_#{::Waistband.config.env}"
        else
          alias_name
        end
      end

      def custom_name?
        !!config['name']
      end

      def types
        config.try(:[], 'mappings').try(:keys) || []
      end

      def default_type_name
        @index_name.singularize
      end

      def config_name
        @subs ? "#{base_config_name}__#{@subs.join('_')}" : base_config_name
      end

      def base_config_name
        return config['name'] if config['name']
        "#{@index_name}_#{::Waistband.config.env}"
      end

    # /private

  end
end

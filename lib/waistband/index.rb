require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/hash/keys'

module Waistband
  class Index

    delegate  :create!, :create, :destroy!, :destroy,
              :update_settings!, :update_settings,
              :delete!, :delete, :read!, :read,
              :alias, :alias!,
              :fetch_alias, :mapping, :exists?,
              :refresh!, :refresh,
              :search_url,
              to: :connection

    attr_reader :base_name

    def initialize(index, options = {})
      options = options.stringify_keys

      @index          = index
      @base_name      = index
      @stringify      = config['stringify']

      @subs = [options['subs']] if options['subs'].present?
      @subs = @subs.flatten     if @subs.is_a?(Array)
    end

    def store!(key, data)
      # map everything to strings
      if @stringify
        original_data = data
        data = stringify_all data
      end

      result = connection.put key, data
      data = original_data if @stringify

      result
    end

    def query(options = {})
      ::Waistband::Query.new self, options
    end

    def name
      @subs ? "#{@index}__#{@subs.join('_')}" : @index
    end

    def config_name
      @subs ? "#{base_config_name}__#{@subs.join('_')}" : base_config_name
    end

    def config_json
      config.except('name', 'stringify').to_json
    end

    def base_config_name
      return config['name'] if config['name']
      "#{@base_name}_#{env}"
    end

    def custom_name?
      !!config['name']
    end

    def config
      Waistband.config.index @index
    end

    def env
      Waistband.config.env
    end

    private

      def stringify_all(data)
        data = if data.is_a? Array
          ::Waistband::StringifiedArray.new data
        elsif data.is_a? Hash
          ::Waistband::StringifiedHash.new_from data
        end

        data = data.stringify_all if data.respond_to? :stringify_all
        data
      end

      def connection
        ::Waistband::Connection.new self
      end

    # /private

  end
end

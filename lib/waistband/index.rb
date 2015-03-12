require 'active_support/core_ext/hash/keys'
require 'active_support/core_ext/array/extract_options'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/hash/reverse_merge'
require 'elasticsearch'

module Waistband
  class Index

    BODY_SIZE_LIMIT = 100_000

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

    def update_all_mappings
      check_permission!('create')

      responses = types.map do |type|
        update_mapping(type).merge('_type' => type)
      end
    end

    def update_mapping(type)
      check_permission!('create')

      properties = config['mappings'][type]['properties'] || {}

      mapping_hash = {type => {properties: properties}}

      client.indices.put_mapping(
        index: config_name,
        type: type,
        body: mapping_hash
      )
    end

    def update_settings
      check_permission!('create')

      client.indices.put_settings(
        index: config_name,
        body: settings
      )
    end

    def create
      create!
    rescue ::Waistband::Errors::IndexExists => ex
      true
    end

    def create!
      check_permission!('create')

      client.indices.create index: config_name, body: config.except('name', 'permissions', 'stringify', 'log_level')
    rescue Elasticsearch::Transport::Transport::Errors::BadRequest => ex
      raise ex unless ex.message.to_s =~ /IndexAlreadyExistsException/
      raise ::Waistband::Errors::IndexExists.new("Index already exists")
    end

    def delete
      delete!
    rescue ::Waistband::Errors::IndexNotFound => ex
      true
    end

    def delete!
      check_permission!('delete_index')

      client.indices.delete index: config_name
    rescue Elasticsearch::Transport::Transport::Errors::NotFound => ex
      raise ex unless ex.message.to_s =~ /IndexMissingException/
      raise ::Waistband::Errors::IndexNotFound.new("Index not found")
    end

    def save!(*args)
      check_permission!('write')

      body_hash = args.extract_options!
      id = args.first
      _type = body_hash.delete(:_type) || body_hash.delete('_type') || default_type_name

      # map everything to strings if need be
      body_hash = stringify_all(body_hash) if @stringify

      verify_body_size(config_name, _type, id, body_hash)

      saved = client.index(
        index: config_name,
        type: _type,
        id: id,
        body: body_hash
      )

      unless saved['_id'].present?
        raise ::Waistband::Errors::UnableToSave.new("Unable to save to index: #{config_name}, type: #{_type}, id: #{id}: result: #{saved}")
      end

      saved
    end

    def save(*args)
      save!(*args)
    rescue ::Waistband::Errors::UnableToSave => ex
      false
    end

    def find(id, options = {})
      find!(id, options)
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      nil
    end

    def find!(id, options = {})
      doc = read!(id, options)
      doc['_source']
    end

    def read_result(id, options = {})
      read_result!(id, options)
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      nil
    end

    def read_result!(id, options = {})
      hit = read!(id, options)
      ::Waistband::Result.new(hit)
    end

    def read(id, options = {})
      read!(id, options)
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      nil
    end

    def read!(id, options = {})
      check_permission!('read')

      options = options.with_indifferent_access
      type = options[:_type] || default_type_name

      client.get(
        index: config_name,
        type: type,
        id: id
      ).with_indifferent_access
    end

    def destroy(id, options = {})
      destroy!(id, options)
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      nil
    end

    def destroy!(id, options = {})
      check_permission!('destroy')

      options = options.with_indifferent_access
      type = options[:_type] || default_type_name

      client.delete(
        index: config_name,
        id: id,
        type: type
      )
    end

    def search(body_hash)
      page, page_size = get_page_info body_hash
      body_hash       = parse_search_body(body_hash)
      _type           = body_hash.delete(:_type)
      search_hash     = {index: config_name, body: body_hash}

      search_hash[:type] = _type if _type
      search_hash[:from] = body_hash[:from] if body_hash[:from]
      search_hash[:size] = body_hash[:size] if body_hash[:size]

      search_hash = client.search(search_hash)

      ::Waistband::SearchResults.new(search_hash, page: page, page_size: page_size)
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

      def verify_body_size(index_config_name, type, id, body_hash)
        body_json = body_hash.to_json
        size = body_json.bytesize

        if size > BODY_SIZE_LIMIT
          msg  = "verify_body_size: Body size larger than limit.  "
          msg << "Current size: #{size}.  Limit: #{BODY_SIZE_LIMIT}.  "
          msg << "index_config_name: #{index_config_name}.  _type: #{type}.  id: #{id}.  "
          msg << "body: #{body_json[0, 1000]}"
          log_warning(msg)
        end
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

      def get_page_info(body_hash)
        page = body_hash[:page]
        page_size = body_hash[:page_size]
        [page, page_size]
      end

      def parse_search_body(body_hash)
        body_hash = body_hash.with_indifferent_access

        page = body_hash.delete(:page)
        page_size = body_hash.delete(:page_size)

        if page || page_size
          page ||= 1
          page = page.to_i
          page_size ||= 20
          body_hash[:from] = page_size * (page - 1) unless body_hash[:from]
          body_hash[:size] = page_size              unless body_hash[:size]
        end

        body_hash
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

      def stringify_all(data)
        data = if data.is_a? Array
          ::Waistband::StringifiedArray.new data
        elsif data.is_a? Hash
          ::Waistband::StringifiedHash.new_from data
        end

        data = data.stringify_all if data.respond_to? :stringify_all
        data
      end

      def types
        config.try(:[], 'mappings').try(:keys) || []
      end

      def default_type_name
        return default_type_name_from_mappings if default_type_name_from_mappings
        @index_name.singularize
      end

      def default_type_name_from_mappings
        @default_type_name_from_mappings ||= begin
          mappings = (config['mappings'] || {})
          mappings.keys.first
        end
      end

      def settings
        settings = config['settings']['index'].except('number_of_shards')
        {index: settings}
      end

      def config_name
        @subs ? "#{base_config_name}__#{@subs.join('_')}" : base_config_name
      end

      def base_config_name
        return config['name'] if config['name']
        "#{@index_name}_#{::Waistband.config.env}"
      end

      def check_permission!(permission)
        raise "::Waistband::Errors::Permissions::#{permission.classify}".constantize.new("Don't have enough permissions to #{permission} on index #{config_name}") unless check_permission?(permission)
      end

      def check_permission?(permission)
        !!permissions[permission]
      end

      def permissions
        @permissions ||= (config['permissions'] || {}).reverse_merge({
          'create'       => true,
          'delete_index' => true,
          'destroy'      => true,
          'read'         => true,
          'write'        => true
        }).with_indifferent_access
      end

    # /private

  end
end

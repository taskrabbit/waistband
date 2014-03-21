require 'yaml'
require 'active_support/core_ext/hash/indifferent_access'

module Waistband
  class Migrator

    def create_indices
      _create_indices(indices)
    end

    def create_aliases
      response = {}

      aliases_names.each do |alias_name|
        alias_indices_names = alias_indices_names alias_name
        delete_existing_indices alias_name
        response[alias_name] = _create_indices alias_indices_names, alias_name: alias_name
      end

      response.with_indifferent_access
    end

    def indices
      config['indices'] || []
    end

    def aliases
      config['aliases'] || []
    end

    def aliases_names
      aliases.keys
    end

    private

      def delete_existing_indices(alias_name)
        alias_indices_names = alias_indices_names alias_name
        existing_indices = ::Waistband::Index.new(alias_indices_names.first).get_alias alias_name
        schema_indices = alias_indices_names.map{|name| ::Waistband::Index.new(name).config_name}

        existing_indices.each do |index_name|
          unless schema_indices.include? index_name
            real_index_name = real_index_name index_name
            ::Waistband::Index.new(real_index_name).delete
          end
        end
      end

      def alias_indices_names(alias_name)
        config['aliases'][alias_name]
      end

      def real_index_name(index_name_with_env)
        name = index_name_with_env.gsub(/_#{Waistband.config.env}$/, '')
        name
      end

      def _create_indices(indices_names, options = {})
        response = {}

        indices_names.each do |index_name|
          index = ::Waistband::Index.new index_name
          response[index_name] = index.create
          index.alias(options[:alias_name]) if options[:alias_name]
        end

        response.with_indifferent_access
      end

      def config
        @config ||= YAML.load_file("#{::Waistband.config.config_dir}/waistband_schema.yml")[::Waistband.config.env].with_indifferent_access
      end

    # /private

  end
end

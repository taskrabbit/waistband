require 'yaml'
require 'singleton'
require 'active_support/core_ext/hash/indifferent_access'

module Waistband
  class Configuration

    include Singleton

    attr_accessor :config_dir

    def initialize
      @yml_config = {}
      @indexes    = {}
    end

    def setup
      raise "Please define a valid `config_dir` configuration variable!"  unless config_dir
      raise "Couldn't find configuration directory #{config_dir}"         unless File.exist?(config_dir)

      @env        ||= ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'
      @yml_config   = YAML.load_file("#{config_dir}/waistband.yml")[@env].with_indifferent_access
    end

    def index(name)
      @indexes[name] ||= YAML.load_file("#{config_dir}/waistband_#{name}.yml")[@env].with_indifferent_access
    end

    def hostname
      "#{host}:#{port}"
    end

    def method_missing(method_name, *args, &block)
      return current_server[method_name]  if current_server[method_name]
      return @yml_config[method_name]     if @yml_config[method_name]
      super
    end

    private

      def current_server
        servers.sample
      end

      def servers
        @servers ||= @yml_config['servers'].map {|server_name, config| config}
      end

    # /private

  end
end

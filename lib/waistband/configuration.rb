require 'yaml'
require 'singleton'
require 'active_support/core_ext/hash/indifferent_access'
require 'digest/sha1'

module Waistband
  class Configuration

    include Singleton

    attr_accessor :config_dir
    attr_accessor :index_prefix
    attr_writer   :timeout
    attr_reader   :env

    def initialize
      @yml_config = {}
      @indexes    = {}
    end

    def setup
      self.config_dir = default_config_dir unless config_dir

      raise "Please define a valid `config_dir` configuration variable!"  unless config_dir
      raise "Couldn't find configuration directory #{config_dir}"         unless File.exist?(config_dir)

      @env         ||= ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'
      yml            = load_yml_with_erb(File.join(config_dir, 'waistband.yml'))
      @yml_config    = yml[@env].with_indifferent_access
      @adapter       = @yml_config.delete('adapter')
    end

    def index(name)
      return @indexes[name] if @indexes[name]
      yml = load_yml_with_erb(File.join(config_dir, "waistband_#{name}.yml"))
      @indexes[name] = yml[@env].with_indifferent_access
    end

    def method_missing(method_name, *args, &block)
      return @yml_config[method_name] if @yml_config[method_name]
      super
    end

    def hosts
      @hosts ||= @yml_config['servers'].map do |server_name, config|
        config
      end
    end

    def client
      client_hash = {
        adapter: @adapter,
        hosts: hosts,
        randomize_hosts: true,
        retry_on_failure: retries,
        reload_on_failure: reload_on_failure,
        transport_options: {
          request: {
            open_timeout: timeout,
            timeout: timeout
          }
        }
      }

      Elasticsearch::Client.new client_hash
    end

    def reset_timeout
      remove_instance_variable '@timeout'
    end

    private

      def load_yml_with_erb(file)
        if defined?(ERB)
          YAML.load(ERB.new(File.read(file)).result)
        else
          YAML.load_file(file)
        end
      end

      def timeout
        return @timeout if defined? @timeout
        @yml_config['timeout']
      end

      def default_config_dir
        @default_config_dir ||= begin
          return nil unless defined?(Rails)
          File.join(Rails.root, 'config')
        end
      end

    # /private

  end
end

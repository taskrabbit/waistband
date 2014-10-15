module Waistband
  class Client

    class << self

      def from_config(config_hash)
        new(
          config_hash['servers'], randomize_hosts: true,
          retry_on_failure: config_hash['retries'],
          reload_on_failure: config_hash['reload_on_failure'],
          timeout: config_hash['timeout'],
          adapter: config_hash['adapter']
        )
      end

    end

    def initialize(servers, options = {})
      @servers = servers
      @randomize_hosts = options.fetch(:randomize_hosts, true)
      @retry_on_failure = options[:retry_on_failure]
      @reload_on_failure = options[:reload_on_failure]
      @timeout = options[:timeout]
      @adapter = options[:adapter]
    end

    def connection
      @connection ||= Elasticsearch::Client.new config_hash
    end

    def config_hash
      {
        adapter: @adapter,
        hosts: hosts,
        randomize_hosts: @randomize_hosts,
        retry_on_failure: @retry_on_failure,
        reload_on_failure: @reload_on_failure,
        transport_options: {
          request: {
            open_timeout: @timeout,
            timeout: @timeout
          }
        }
      }
    end

    def method_missing(method_name, *args, &block)
      return connection.send(method_name, *args, &block) if connection.respond_to?(method_name)
      super
    end

    private

      def hosts
        @hosts ||= @servers.map do |server_name, config|
          config
        end
      end

  end
end

module Waistband
  module IndexOperations
    module Settings

      INTERVAL_OFF        = '-1'.freeze
      INTERVAL_DEFAULT_ON = '1s'.freeze

      def get_settings
        client.indices.get_settings[config_name]
      end

      def update_all_mappings
        responses = types.map do |type|
          update_mapping(type).merge('_type' => type)
        end
      end

      def update_mapping(type)
        properties = config['mappings'][type]['properties'] || {}

        mapping_hash = {type => {properties: properties}}

        client.indices.put_mapping(
          index: config_name,
          type: type,
          body: mapping_hash
        )
      end

      def update_settings
        client.indices.put_settings(
          index: config_name,
          body: settings
        )
      end

      def refresh_off
        updated = client.indices.put_settings(
          index: config_name,
          body: {
            refresh_interval: INTERVAL_OFF
          }
        )

        !!updated['acknowledged']
      end

      def refresh_on
        infer_on_interval = settings.try(:[], :index).try(:[], :refresh_interval) || INTERVAL_DEFAULT_ON

        updated = client.indices.put_settings(
          index: config_name,
          body: {
            refresh_interval: infer_on_interval
          }
        )

        !!updated['acknowledged']
      end

      private

        def settings
          settings = config['settings']['index'].except('number_of_shards')
          {index: settings}.with_indifferent_access
        end

    end
  end
end

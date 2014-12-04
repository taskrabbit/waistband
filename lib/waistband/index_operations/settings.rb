module Waistband
  module IndexOperations
    module Settings

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

    end
  end
end

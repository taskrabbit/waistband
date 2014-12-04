module Waistband
  module IndexOperations
    module Bulk

      def bulk(actions)
        _acts = es_actions(actions)
      end

      private

        def es_actions(actions)
          actions.map do |args|
            action_to_es_api_action(args)
          end
        end

        def action_to_es_api_action(args)
          body_hash = args.extract_options!
          action_name = args[0]
          _id = args[1]
          _type = infer_type(body_hash)

          {
            action_name.to_sym => {
              _index: config_name,
              _type: _type,
              _id: _id,
              data: body_hash
            }
          }
        end

    end
  end
end

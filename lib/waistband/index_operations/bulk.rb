module Waistband
  module IndexOperations
    module Bulk

      def bulk(*args)
        options = args.extract_options!
        actions = args.first

        body = actions.map do |action_hash|
          action_to_api_action(action_hash)
        end

        saved = client.bulk({
          body: body
        })

        saved['errors'] != true
      end

      private

        def action_to_api_action(action_hash)
          action_hash.stringify_keys!

          action_name = action_hash['action']
          _id         = action_hash['id']

          body_hash = action_hash['body']
          _type     = infer_type(body_hash)

          {
            action_name.to_sym => {
              _index: config_name,
              _type:  _type,
              _id:    _id,
              data:   body_hash
            }
          }
        end

    end
  end
end

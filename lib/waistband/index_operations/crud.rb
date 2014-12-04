module Waistband
  module IndexOperations
    module Crud

      BODY_SIZE_LIMIT = 100_000

      def create
        create!
      rescue ::Waistband::Errors::IndexExists => ex
        true
      end

      def create!
        client.indices.create index: config_name, body: config.except('name', 'stringify', 'log_level')
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
        client.indices.delete index: config_name
      rescue Elasticsearch::Transport::Transport::Errors::NotFound => ex
        raise ex unless ex.message.to_s =~ /IndexMissingException/
        raise ::Waistband::Errors::IndexNotFound.new("Index not found")
      end

      def save(*args)
        with_body_prelude(args) do |id, _type, body_hash|
          saved = client.index(
            index: config_name,
            type: _type,
            id: id,
            body: body_hash
          )

          saved['_id'].present?
        end
      end

      def update(*args)
        with_body_prelude(args) do |id, _type, body_hash|
          saved = client.update(
            index: config_name,
            type: _type,
            id: id,
            body: body_hash
          )

          saved['_id'].present?
        end
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
        options = options.with_indifferent_access
        type = options[:_type] || default_type_name

        client.delete(
          index: config_name,
          id: id,
          type: type
        )
      end

      private

        def with_body_prelude(args)
          body_hash = args.extract_options!
          id = args.first
          _type = body_hash.delete(:_type) || body_hash.delete('_type') || default_type_name

          # map everything to strings if need be
          body_hash = stringify_all(body_hash) if @stringify

          verify_body_size(config_name, _type, id, body_hash)

          yield(id, _type, body_hash)
        end

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

        def stringify_all(data)
          data = if data.is_a? Array
            ::Waistband::StringifiedArray.new data
          elsif data.is_a? Hash
            ::Waistband::StringifiedHash.new_from data
          end

          data = data.stringify_all if data.respond_to? :stringify_all
          data
        end

    end
  end
end

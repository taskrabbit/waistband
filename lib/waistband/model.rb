require 'digest/md5'

module Waistband
  class Model

    raise "ActiveModel not defined!" unless defined?(ActiveModel)

    include ::ActiveModel::Model
    include ::ActiveModel::Serializers::JSON
    include ::ActiveModel::Validations
    include ::ActiveModel::Dirty

    class << self

      attr_reader :_index, :column_names

      # lil dsl for attrs
      def columns(*names)
        @column_names = [:id]
        attr_accessor :id

        names.each do |name|
          @column_names << name.to_sym
          attr_accessor name
        end

        @column_names.uniq!
        @column_names
      end

      # index proxy
      def index(index_name)
        @_index = ::Waistband::Index.new(index_name)
      end

    end

    def index
      self.class._index
    end

    def attributes
      attrs = {}
      self.class.column_names.each do |column_name|
        attrs[column_name] = self.send(column_name)
      end
      attrs
    end

    def save
      set_id = false

      unless id
        set_id = true
        self.id = digest
      end

      result = index.save(id, attributes.except(:id))

      if !result && set_id
        self.id = nil
      end

      result
    end

    def save!

    end

    def digest
      content = (self.class.column_names - [:id]).map{|column_name| self.send(column_name) }.join('-')
      Digest::MD5.hexdigest content
    end

  end
end


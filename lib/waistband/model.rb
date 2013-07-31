require 'digest/md5'
require 'json'
require 'active_support/core_ext/class/attribute'
require 'active_support/values/time_zone'
require 'active_support/time_with_zone'

module Waistband
  class Model

    class_attribute :index_name, :column_names, :validate_columns,
                    :default_values, :stringify_columns

    class << self

      def index
        @index ||= Waistband::Index.new(index_name)
      end

      def find(id)
        attrs = index.read(id)
        raise ActiveRecord::RecordNotFound.new("#{self} not found!") unless attrs
        new attrs
      end

      def create(attributes)
        instance = new(attributes)
        instance.save
        instance
      end

      def query
        q = index.query('')
        q.add_term('model_type', name.underscore)
        q
      end

      def query_desc
        q = query
        q.add_sort 'created_at', 'desc'
        q
      end

      def query_asc
        q = query
        q.add_sort 'created_at', 'asc'
        q
      end

      def first
        query_asc.results.first
      end

      def last
        query_desc.results.first
      end

      def with_index(name)
        self.index_name = name.to_s
      end

      def create_index!
        Waistband::Index.new(index_name).create!
      end

      def destroy_index!
        Waistband::Index.new(index_name).destroy!
      end

      def validates(*cols)
        self.validate_columns ||= []
        self.validate_columns |= cols.map(&:to_sym)
      end

      def defaults(values = {})
        self.default_values ||= {}

        values.each do |k, v|
          self.default_values = self.default_values.merge({k.to_sym => v})
        end
      end

      def stringify(*cols)
        self.stringify_columns ||= []
        self.stringify_columns |= cols.map(&:to_sym)
      end

      def columns(*cols)
        cols               |= [:id, :model_type, :created_at, :updated_at]
        self.column_names ||= []
        self.column_names  |= cols.map(&:to_sym)

        cols.each do |col|
          # Normal attributes setters and getters
          class_eval <<-EV, __FILE__, __LINE__ + 1
            def #{col}
              read_attribute(:#{col})
            end

            def #{col}=(val)
              write_attribute(:#{col}, val)
            end
          EV

          # Relationship type columns: `user_id`, `app_id` to `user`, `app`
          if col =~ /(.*)_id$/
            class_eval <<-EV, __FILE__, __LINE__ + 1
              def #{$1}
                klass = "#{$1}".classify.constantize
                klass.find(#{col})
              end

              def #{$1}=(val)
                write_attribute(:#{$1}_id, val.id)
              end
            EV
          end

        end
      end

    end # /class << self

    attr_reader :errors

    def initialize(attributes = {})
      @attributes = (attributes || {}).symbolize_keys

      @attributes.each do |key, val|
        if self.class.stringify_columns.include?(key)
          self.send("#{key}=", val)
        elsif !self.class.column_names.include?(key)
          raise ArgumentError.new("#{key} is not a valid column name!")
        end  
      end

      self.class.default_values.each do |k, v|
        self.send("#{k}=", v) if self.send(k).nil?
      end

      @errors = ::Waistband::QuickError.new
    end

    def save
      return false unless valid?

      before_save

      prev_id         = self.id
      prev_created_at = self.created_at
      prev_updated_at = self.updated_at

      self.id         ||= generated_id
      self.created_at ||= (Time.zone || Time).now.to_i
      self.updated_at   = (Time.zone || Time).now.to_i
      self.model_type   = self.class.name.downcase

      stored_json = JSON.parse store!
      stored      = !!stored_json.try(:[], 'ok')

      if stored
        after_save
      else stored
        self.id         = prev_id
        self.created_at = prev_created_at
        self.updated_at = prev_updated_at
      end

      stored
    end

    def before_save
    end

    def after_save
    end

    def valid?
      self.class.validate_columns.each do |col|
        @errors << "#{col} cannot be nil" if self.send(col).nil?
      end

      @errors.empty?
    end

    def attributes
      Hash[self.class.column_names.map{|col| [col, self.send(col)] }]
    end

    def read_attribute(attribute)
      @attributes[attribute]
    end

    def write_attribute(attribute, val)
      val = val.to_s if self.class.stringify_columns.include?(attribute.to_sym)
      @attributes[attribute] = val
    end

    private

      def store!
        self.class.index.store!(id, attributes)
      end

      def generated_id
        @generated_id ||= Digest::SHA1.hexdigest "#{attributes}:#{rand(999999)}"
      end

    # /private

  end
end

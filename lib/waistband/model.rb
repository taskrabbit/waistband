require 'active_support/core_ext/object/blank'
require 'active_model'

module Waistband
  class Model


    include ::ActiveModel::Validations


    #################
    # Class methods #
    #################

    class << self

      attr_reader :type_name, :column_defaults

      def index_name(name)
        @index_name = name.to_s
      end

      def index_type(name)
        @type_name = name.to_s
      end

      def index
        raise "index_name not defined!" if @index_name.blank?
        Waistband::Index.new(@index_name)
      end

      def defaults(defaults)
        @column_defaults ||= {}
        @column_defaults.merge!(defaults)
      end

    end


    delegate :index, :type_name, :column_defaults, to: :'self.class'
    
    attr_accessor :attributes


    def initialize(attributes = {})
      self.attributes = (column_defaults || {}).merge(attributes.symbolize_keys)
    end


    #########
    # Index #
    #########

    def property_names
      index.config['mappings'][type_name]['properties'].keys
    end

    ##############
    # Attributes #
    ##############

    def method_missing(method_name, *args, &block)
      method_name_without_eq = method_name.to_s.gsub('=', '')

      if self.attributes.has_key?(method_name)
        # attribute in place not by mappings but by defaults
        return read_attribute(method_name)
      elsif property_names.include?(method_name.to_s)
        # attribute reader (model.attribute_name)
        return read_attribute(method_name)
      elsif property_names.include?(method_name_without_eq)
        # attribute writer (model.attribute_name=)
        write_attribute(method_name_without_eq, *args)
      else
        super
      end
    end

    def read_attribute(key)
      self.attributes[key]
    end

    def write_attribute(key, *args)
      val = args.first
      self.attributes[key.to_sym] = val
    end


  end
end

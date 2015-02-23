require 'digest/md5'
require 'active_support/core_ext/object/blank'
require 'active_model'

module Waistband
  class Model

    extend ::ActiveModel::Callbacks

    include ::ActiveModel::Validations
    include ::ActiveModel::Validations::Callbacks


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

      def create(attributes = {})
        obj = new(attributes)
        obj.save
        obj
      end

      def create!(attributes = {})
        obj = new(attributes)
        obj.save!
        obj
      end

      def find(id)
        found_attributes = index.find(id)

        unless found_attributes
          raise ::Waistband::Errors::Model::NotFound.new("Couldn't find #{self} with 'id'=#{id}")
        end

        new(found_attributes.merge(id: id, persisted: true))
      end

      def count
        query_hash = {_type: type_name}
        index.search(query_hash).total_results
      end

      def search(query_hash)
        # add type to query_hash
        query_hash.merge!(_type: type_name)

        hits = index.search(query_hash).hits
        hits.map do |hit|
          id = hit['_id']
          new(hit['_source'].merge(id: id))
        end
      end

    end


    define_model_callbacks :save, :create, :destroy, :commit, :update

    delegate :index, :type_name, :column_defaults, to: :'self.class'

    attr_accessor :attributes, :persisted, :id


    def initialize(attributes = {})
      attributes = attributes.symbolize_keys

      self.id = attributes.delete(:id)
      self.persisted = attributes.delete(:persisted)

      self.attributes = ((column_defaults || {}).merge(attributes)).symbolize_keys
    end

    def inspect
      "#<#{self.class.name}:#{self.object_id} #{self.attributes.map{|k,v| "#{k}: #{v.inspect}"}.join(', ')}>"
    end


    #########
    # Index #
    #########

    def property_names
      index.config['mappings'][type_name]['properties'].keys.map(&:to_sym)
    end

    ##############
    # Attributes #
    ##############

    def method_missing(method_name, *args, &block)
      method_name_wout_eq = method_name.to_s.gsub('=', '')

      if self.attributes.has_key?(method_name)
        # attribute in place not by mappings but by defaults
        return read_attribute(method_name)
      elsif property_names.include?(method_name)
        # attribute reader (model.attribute_name)
        return read_attribute(method_name)
      elsif property_names.include?(method_name_wout_eq)
        # attribute writer (model.attribute_name=)
        write_attribute(method_name_wout_eq, *args)
      elsif method_name.to_s.match(/.+=$/)
        # set unknown attribute
        write_attribute(method_name_wout_eq, *args)
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

    ###############
    # Persistence #
    ###############

    def save
      result = false

      return false unless self.valid?

      run_callbacks :commit do
        if self.new_record?
          run_callbacks :create do
            run_callbacks :save do
              result = persist!
            end
          end
        else
          run_callbacks :update do
            run_callbacks :save do
              result = persist!
            end
          end
        end
      end

      self.persisted = true if !self.persisted && result
      result
    end

    def save!
      result = save

      unless result
        raise ::Waistband::Errors::Model::UnableToSave.new("Save not successful: #{errors.full_messages}")
      end

      result
    end

    def persist!
      set_id = false

      unless self.id
        self.id = digest
        set_id = true
      end

      val = persist_to_es!

      self.id = nil if !val && set_id

      val
    end

    def persist_to_es!
      # TODO: this should blow up if it fails
      index.save(id, attributes)
    end

    def new_record?
      !self.persisted?
    end

    def persisted?
      !!persisted
    end

    def digest
      keys = (property_names + column_defaults.keys).uniq
      content = (keys - [:id]).map{|key| self.send(key) }.join('-')
      Digest::MD5.hexdigest(content)
    end


  end
end

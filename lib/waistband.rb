require "waistband/version"

module Waistband

  autoload :Errors,           "waistband/errors"
  autoload :StringifiedArray, "waistband/stringified_array"
  autoload :StringifiedHash,  "waistband/stringified_hash"
  autoload :Client,           "waistband/client"
  autoload :Configuration,    "waistband/configuration"
  autoload :Index,            "waistband/index"
  autoload :SearchResults,    "waistband/search_results"
  autoload :Result,           "waistband/result"
  autoload :Model,            "waistband/model"

  class << self

    def configure
      yield ::Waistband::Configuration.instance if block_given?
      config_instance = ::Waistband::Configuration.instance
      config_instance.setup
      config_instance
    end
    alias_method :config, :configure

    def client
      ::Waistband.config.client
    end

  end

end

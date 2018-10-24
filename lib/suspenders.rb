require "suspenders/version"

module Suspenders

  autoload :Errors,           "suspenders/errors"
  autoload :StringifiedArray, "suspenders/stringified_array"
  autoload :StringifiedHash,  "suspenders/stringified_hash"
  autoload :Client,           "suspenders/client"
  autoload :Configuration,    "suspenders/configuration"
  autoload :Index,            "suspenders/index"
  autoload :SearchResults,    "suspenders/search_results"
  autoload :Result,           "suspenders/result"

  class << self

    def configure
      yield ::Suspenders::Configuration.instance if block_given?
      config_instance = ::Suspenders::Configuration.instance
      config_instance.setup
      config_instance
    end
    alias_method :config, :configure

    def client
      ::Suspenders.config.client
    end

  end

end

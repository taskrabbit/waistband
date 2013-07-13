require "waistband/version"

module Waistband
  
  autoload :Configuration,  "waistband/configuration"
  autoload :StringifyAll,   "waistband/stringify_all"
  autoload :QueryResult,    "waistband/query_result"
  autoload :Query,          "waistband/query"
  autoload :Index,          "waistband/index"

  class << self

    def configure
      yield ::Waistband::Configuration.instance if block_given?
      config_instance = ::Waistband::Configuration.instance
      config_instance.setup
      config_instance
    end
    alias_method :config, :configure

  end

end

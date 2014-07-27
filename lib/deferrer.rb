require 'redis'
require "deferrer/version"

module Deferrer
  autoload :Configuration, 'deferrer/configuration'
  autoload :JsonEncoding,  'deferrer/json_encoding'
  autoload :Runner,        'deferrer/runner'
  autoload :Job,           'deferrer/job'

  LIST_KEY        = 'deferred_list'
  ITEM_KEY_PREFIX = 'deferred'

  extend Configuration
  extend JsonEncoding
  extend Runner

  class WorkerNotConfigured < NotImplementedError
    def initialize
      super("Deferrer worker not configured")
    end
  end
end

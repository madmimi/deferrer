require 'redis'
require "deferrer/version"

module Deferrer
  autoload :Configuration, 'deferrer/configuration'
  autoload :Runner,        'deferrer/runner'
  autoload :Worker,        'deferrer/worker'
  autoload :Item,          'deferrer/item'
  autoload :Queue,         'deferrer/queue'
  autoload :Processor,     'deferrer/processor'

  extend Configuration
  extend Runner
end

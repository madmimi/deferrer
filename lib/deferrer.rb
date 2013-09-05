require 'redis'
require "deferrer/version"

module Deferrer

  autoload :Configuration, 'deferrer/configuration'
  autoload :JsonEncoding,  'deferrer/json_encoding'
  autoload :Deferral,      'deferrer/deferral'

  extend Configuration
  extend JsonEncoding
  extend Deferral
end

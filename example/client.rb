require 'deferrer'
require_relative './name_deferrer'

Deferrer.redis_config = { :host => "localhost", :port => 6379 }

Deferrer.defer_in(5, 'identifier', NameDeferrer, 'User', '1')
Deferrer.defer_in(6, 'identifier', NameDeferrer, 'User', '2')
Deferrer.defer_in(9, 'identifier', NameDeferrer, 'User', '3')

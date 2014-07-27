require 'deferrer'
require 'logger'
require_relative './common'

puts 'Runner started'

Deferrer.redis_config = { :host => "localhost", :port => 6379, :db => 15 }
Deferrer.logger = Logger.new(STDOUT)
Deferrer.worker = lambda do |*args|
  p args
end
Deferrer.run({
  :loop_frequency => 0.5,
})

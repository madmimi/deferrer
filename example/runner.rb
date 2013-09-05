require 'deferrer'
require_relative './name_deferrer'

Deferrer.redis_config = { :host => "localhost", :port => 6379 }

class Logger
  def self.info(message)
    puts "INFO: #{message}"
  end

  def self.error(message)
    puts "ERROR: #{message}"
  end
end

puts 'Runner started'

Deferrer.run({
  :loop_frequency => 0.5,
  :logger => Logger
})

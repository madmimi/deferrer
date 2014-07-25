require 'deferrer'
require 'logger'

LOGGER = Logger.new(STDOUT)

# Setup redis
Deferrer.redis_config = { :host => "localhost", :port => 6379 }
Deferrer.logger = LOGGER

# Define deferrer worker
class Worker
  include Deferrer::Job

  pool_options size: 10

  def perform(update)
    sleep 1
    puts update
  end
end

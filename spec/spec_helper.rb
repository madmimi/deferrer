require 'deferrer'

Deferrer.redis_config = { :host => "localhost", :port => 6379 }


ROOT = File.expand_path('../', File.dirname(__FILE__))

# Load support files
Dir["#{ROOT}/spec/support/**/*.rb"].each { |f| require f }


RSpec.configure do |config|
  config.include Helpers

  config.before :each do
    Deferrer.redis.flushdb
  end
end


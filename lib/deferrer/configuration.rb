module Deferrer
  module Configuration

    # Deferrer.redis_config = { :host => "localhost", :port => 6379 }
    def redis_config=(config)
      @redis = Redis.new(config)
    end

    # Returns the configured Redis instance
    def redis
      @redis
    end
  end
end

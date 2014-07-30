module Deferrer
  module Configuration

    attr_reader :redis
    attr_accessor :logger
    attr_accessor :inline

    # Deferrer.redis_config = { :host => "localhost", :port => 6379 }
    def redis_config=(config)
      @redis = Redis.new(config)
    end

    def log(type, message)
      logger.send(type, message) if logger
    end
  end
end

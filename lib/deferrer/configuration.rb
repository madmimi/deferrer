module Deferrer
  module Configuration

    attr_reader :redis
    attr_accessor :logger
    attr_accessor :worker

    # Deferrer.redis_config = { :host => "localhost", :port => 6379 }
    def redis_config=(config)
      @redis = Redis.new(config)
    end
  end
end

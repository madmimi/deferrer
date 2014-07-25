module Deferrer
  module Configuration

    attr_reader :redis
    attr_accessor :logger

    # Deferrer.redis_config = { :host => "localhost", :port => 6379 }
    def redis_config=(config)
      @redis = Redis.new(config)
    end

    def inline=(inline)
      @inline = inline
    end

    def inline?
      !!@inline
    end
  end
end

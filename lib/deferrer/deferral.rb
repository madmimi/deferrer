module Deferrer
  module Deferral

    LIST_KEY = :deferred_list

    def run(options = {})
      loop_frequency = options.fetch(:loop_frequency, 0.1)
      single_run     = options.fetch(:single_run, false)
      @logger        = options.fetch(:logger, nil)
      @before_each   = options.fetch(:before_each, nil)
      @after_each    = options.fetch(:after_each, nil)

      loop do
        while item = next_item
          process_item(item)
        end

        break if single_run
        sleep loop_frequency
      end
    end

    def next_item
      item = nil
      decoded_item = nil
      score = calculate_score(Time.now)

      key = redis.zrangebyscore(LIST_KEY, '-inf', score, :limit => [0, 1]).first

      if key
        item = redis.rpop(key)
        if item
          decoded_item = decode(item)
          decoded_item['key'] = key
        end

        remove(key)
      end

      decoded_item
    end

    def constantize(klass_string)
      klass_string.split('::').inject(Object) do |object, name|
        object = object.const_get(name)
        object
      end
    end

    def defer_in(number_of_seconds_from_now, identifier, klass, *args)
      timestamp = Time.now + number_of_seconds_from_now
      defer_at(timestamp, identifier, klass, *args)
    end

    def defer_at(timestamp, identifier, klass, *args)
      item = build_item(klass, args)
      key = item_key(identifier)
      score = calculate_score(timestamp)

      count = redis.rpush(key, encode(item))

      # set score only on first update
      if count == 1
        redis.zadd(LIST_KEY, score, key)
      end
    end

    def item_key(identifier)
      "deferred:#{identifier}"
    end

    private
    def process_item(item)
      @before_each.call if @before_each
      klass = constantize(item['class'])
      args  = item['args']

      @logger.info("Executing: #{item['key']}") if @logger

      klass.send(:perform, *args)
      @after_each.call if @after_each
    rescue Exception => e
      @logger.error("Error: #{e.class}: #{e.message}") if @logger
    end

    def build_item(klass, args)
      {'class' => klass.to_s, 'args' => args}
    end

    def calculate_score(timestamp)
      timestamp.to_f
    end

    def remove(key)
      redis.watch(key)
      redis.multi do
        redis.del(key)
        redis.zrem(LIST_KEY, key)
      end
      redis.unwatch
    end
  end
end

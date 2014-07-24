module Deferrer
  module Runner
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

    def defer_in(number_of_seconds_from_now, identifier, klass, *args)
      timestamp = Time.now + number_of_seconds_from_now
      defer_at(timestamp, identifier, klass, *args)
    end

    def defer_at(timestamp, identifier, klass, *args)
      key  = item_key(identifier)
      item = build_item(klass, args)

      if Deferrer.inline?
        process_item(decode(encode(item)))
      else
        push_item(key, item, timestamp)
      end
    end

    private
    def process_item(item)
      @before_each.call if @before_each
      klass = constantize(item['class'])
      args  = item['args']

      @logger.info("Executing: #{item['key']}") if @logger

      begin
        klass.send(:perform, *args)
      rescue Exception => e
        @logger.error("Error: #{e.class}: #{e.message}") if @logger
      end

      @after_each.call if @after_each
    end

    def build_item(klass, args)
      {'class' => klass.to_s, 'args' => args}
    end

    def item_key(identifier)
      "#{ITEM_KEY_PREFIX}:#{identifier}"
    end

    def push_item(key, item, timestamp)
      count = redis.rpush(key, encode(item))

      # set score only on first update
      if count == 1
        score = calculate_score(timestamp)
        redis.zadd(LIST_KEY, score, key)
      end
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

    def constantize(klass_string)
      klass_string.split('::').inject(Object) do |object, name|
        object = object.const_get(name)
        object
      end
    end
  end
end

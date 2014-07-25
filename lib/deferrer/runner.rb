module Deferrer
  module Runner

    def run(options = {})
      loop_frequency = options.fetch(:loop_frequency, 0.1)
      single_run     = options.fetch(:single_run, false)

      loop do
        begin
          while item = next_item
            process_item(item)
          end

        rescue StandardError => e
          log(:error, "Error: #{e.class}: #{e.message}")
        rescue Exception => e
          log(:error, "Error: #{e.class}: #{e.message}")
          raise
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
        process_item(decode(encode(item)), false)
      else
        push_item(key, item, timestamp)
      end
    end

    def process_item(item, async = true)
      klass = constantize(item['class'])
      args  = item['args']

      log(:info, "Executing #{klass}#perform with args: #{args}")

      if async
        raise WorkerNotImplemented unless klass.included_modules.include?(Deferrer::Job)
        klass.pool.async.send(:perform, *args)
      else
        klass.new.send(:perform, *args)
      end
    end

    private
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

    def log(type, message)
      logger.send(type, message) if logger
    end
  end
end

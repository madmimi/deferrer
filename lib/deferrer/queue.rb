module Deferrer
  class Queue
    LIST_KEY        = 'deferred_list'
    ITEM_KEY_PREFIX = 'deferred'

    class << self
      def push(item, timestamp)
        key = item_key(item.id)
        count = redis.rpush(key, item.to_json)

        # set score only on first update
        if count == 1
          score = calculate_score(timestamp)
          redis.zadd(LIST_KEY, score, key)
        end
      end

      def pop(ignore_time = false)
        find(next_key(ignore_time))
      end

      def find_by_id(id)
        return nil unless id
        find(item_key(id))
      end

      def find(key)
        return nil unless key

        item = nil

        if json = redis.rpop(key)
          item = Item.from_json(json)
        end

        remove(key)

        item
      end

      private
      def next_key(ignore_time)
        if ignore_time
          redis.zrange(LIST_KEY, 0, 1).first
        else
          score = calculate_score(Time.now)
          redis.zrangebyscore(LIST_KEY, '-inf', score, :limit => [0, 1]).first
        end
      end

      def remove(key)
        redis.watch(key)
        redis.multi do
          redis.del(key)
          redis.zrem(LIST_KEY, key)
        end
        redis.unwatch
      end

      def calculate_score(timestamp)
        timestamp.to_f
      end

      def item_key(id)
        "#{ITEM_KEY_PREFIX}:#{id}"
      end

      def redis
        Deferrer.redis
      end
    end
  end
end

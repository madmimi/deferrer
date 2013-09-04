require 'redis'
require "deferrer/version"

module Deferrer

  LIST_KEY = :deferred_list

  autoload :JsonEncoding,  'deferrer/json_encoding'
  autoload :Configuration, 'deferrer/configuration'

  extend Configuration
  extend JsonEncoding

  def self.defer_in(number_of_seconds_from_now, identifier, klass, *args)
    timestamp = Time.now + number_of_seconds_from_now
    defer_at(timestamp, identifier, klass, *args)
  end

  def self.defer_at(timestamp, identifier, klass, *args)
    item = build_item(klass, args)
    key = item_key(identifier)
    score = calculate_score(timestamp)

    redis.rpush(key, encode(item))
    redis.zadd(LIST_KEY, score, key)
  end

  def self.next_item
    item = nil
    decoded_item = nil
    score = calculate_score(Time.now)

    key = redis.zrangebyscore(LIST_KEY, '-inf', score, :limit => [0, 1]).first

    if key
      _, item = redis.brpop(key, 0)
      decoded_item = decode(item) if item

      remove(key)
    end

    decoded_item
  end

  private
  def self.item_key(identifier)
    "deferred:#{identifier}"
  end

  def self.build_item(klass, args)
    {'class' => klass.to_s, 'args' => args}
  end

  def self.calculate_score(timestamp)
    timestamp.to_f
  end

  def self.remove(key)
    redis.watch(key)
    redis.multi do
      redis.del(key)
      redis.zrem(LIST_KEY, key)
    end
    redis.unwatch
  end
end

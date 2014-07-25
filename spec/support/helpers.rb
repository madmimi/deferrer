module Helpers
  def item_key(identifier)
    "#{Deferrer::ITEM_KEY_PREFIX}:#{identifier}"
  end

  def run_sync(klass, total = 1)
    klass.queue = Queue.new

    total.times { |i| yield(i) }

    Deferrer.run(single_run: true)
  end
end

class Worker
  include Deferrer::Job
  pool_options size: 3

  class << self
    attr_accessor :queue
  end

  def perform(i)
    Thread.current[:x] = i
    self.class.queue.push(i)
  end
end

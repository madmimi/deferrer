module Helpers
  def item_key(identifier)
    "#{Deferrer::Queue::ITEM_KEY_PREFIX}:#{identifier}"
  end
end

class TestWorker
  include Deferrer::Worker

  def perform(*args)
  end
end

module Helpers
  def item_key(identifier)
    "#{Deferrer::ITEM_KEY_PREFIX}:#{identifier}"
  end
end

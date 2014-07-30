# setup redis
Deferrer.redis_config = { :host => "localhost", :port => 6379, db: 15 }

class WorkDeferrer
  include Deferrer::Worker

  def perform(update)
    p update
  end
end

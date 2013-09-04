module Deferrer
  module Runner

    LOOP_FREQUENCY = 0.1

    def run
      while true do

        # loop all the time if you get items from redis
        while item = next_item
          klass = Module.const_get(item['class'])
          args  = item['args']

          klass.send(:perform, *args)
        end

        sleep LOOP_FREQUENCY
      end
    end
  end
end

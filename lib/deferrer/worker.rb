module Deferrer
  module Worker

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def defer_in(number_of_seconds_from_now, id, *args)
        timestamp = Time.now + number_of_seconds_from_now
        defer_at(timestamp, id, *args)
      end

      def defer_at(timestamp, id, *args)
        item = Item.new(id, name, args)
        Deferrer::Queue.push(item, timestamp)

        if Deferrer.inline
          item = Deferrer::Queue.find_by_id(item.id)
          Processor.new(item).process
        end
      end
    end
  end
end

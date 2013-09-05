module Deferrer
  module Runner

    def run(options)
      loop_frequency = options[:loop_frequency] || 0.1
      logger = options[:logger] || nil

      while true do
        # loop while there're items to process
        while item = next_item
          begin
            klass = constantize(item['class'])
            args  = item['args']

            logger.info("Executing: #{item['key']}") if logger

            klass.send(:perform, *args)
          rescue Exception => e
            logger.error("Error: #{e.class}: #{e.detail}") if logger
          end
        end

        sleep loop_frequency
      end
    end

    def constantize(klass_string)
      klass_string.split('::').inject(Object) {|memo,name| memo = memo.const_get(name); memo}
    end
  end
end

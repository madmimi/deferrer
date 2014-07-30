module Deferrer
  module Runner

    def run(options = {})
      loop_frequency = options.fetch(:loop_frequency, 0.1)
      single_run     = options.fetch(:single_run, false)
      ignore_time    = options.fetch(:ignore_time, false)

      loop do
        begin
          while item = Deferrer::Queue.pop(ignore_time)
            Processor.new(item).process
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
  end
end

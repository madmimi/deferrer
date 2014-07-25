require 'celluloid'

module Deferrer
  module Job
    def self.included(base)
      base.send(:include, ::Celluloid)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def pool_options(options = nil)
        if options
          @pool_options = options
        else
          @pool_options
        end
      end
    end
  end
end

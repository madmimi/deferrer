require 'multi_json'

module Deferrer
  module JsonEncoding

    class DecodeException < StandardError; end

    def encode(item)
      MultiJson.dump(item)
    end

    def decode(item)
      begin
        MultiJson.load(item)
      rescue ::MultiJson::DecodeError => e
        raise DecodeException, e.message, e.backtrace
      end
    end
  end
end

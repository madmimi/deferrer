require 'multi_json'

module Deferrer
  module JsonEncoding

    def encode(item)
      MultiJson.dump(item)
    end

    def decode(item)
      MultiJson.load(item)
    end
  end
end

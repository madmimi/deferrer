require 'multi_json'

module Deferrer
  class Item

    attr_reader :id, :class_name, :args

    def self.from_json(json)
      item = MultiJson.load(json)
      new(item['id'], item['class'], item['args'])
    end

    def initialize(id, class_name, args)
      @id         = id
      @class_name = class_name
      @args       = args
    end

    def to_json
      MultiJson.dump(to_hash)
    end

    def to_hash
      { 'id' => id, 'class' => class_name, 'args' => args }
    end

    def ==(object)
      object.id == self.id
    end
  end
end


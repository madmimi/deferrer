module Deferrer
  class Processor

    def initialize(item)
      @item = item
    end

    def process
      Deferrer.log(:info, "Processing: #{@item.id}")
      klass = constantize(@item.class_name)
      klass.new.send(:perform, *@item.args)
    end

    private
    def constantize(klass_string)
      klass_string.split('::').inject(Object) do |object, name|
        object = object.const_get(name)
        object
      end
    end
  end
end


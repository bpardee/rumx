module Rumx
  class Attribute
    attr_reader :name, :type, :description, :allow_read, :allow_write

    def initialize(name, type, description, allow_read, allow_write, options)
      @name        = name.to_sym
      @type        = type
      @description = description
      # List and hash attributes might set up the object for reading but the individual elements for writing
      @allow_read  = options[:allow_read] || allow_read
      @allow_write = options[:allow_write] || allow_write
      @options     = options
    end

    def get_value(bean)
      @allow_read ? bean.send(@name) : nil
    end

    def each_attribute_info(bean, ancestry, &block)
      yield AttributeInfo.new(self, bean, ancestry+[@name], get_value(bean))
    end

    def write?(bean, params)
      if @allow_write
        param_value(params) do |value|
          bean.send(@name.to_s+'=', @type.string_to_value(value))
          return true
        end
      end
      return false
    end

    def [](key)
      @options[key]
    end

    protected

    def param_value(params, &block)
      if params.has_key?(@name)
        yield params[@name]
      elsif params.has_key?(@name.to_s)
        yield params[@name.to_s]
      end
    end
  end
end

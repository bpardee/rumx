module Rumx
  class Attribute
    attr_reader :name, :type, :description, :allow_read, :allow_write

    def initialize(name, type_name, description, allow_read, allow_write, options)
      @name        = name.to_sym
      @type        = Type.find(type_name)
      @description = description
      @allow_read  = allow_read
      @allow_write = allow_write
      @options     = options
    end

    def get_value(bean)
      return nil unless @allow_read
      bean.send(self.name)
    end

    def set_value(bean, value)
      raise 'Illegal set_value' unless @allow_write
      bean.send(self.name.to_s+'=', type.string_to_value(value))
    end

    def get_index_value(obj, index)
      return nil unless @allow_read
      return obj[index]
    end

    def set_index_value(obj, index, value)
      raise 'Illegal set_index_value' unless @allow_write
      obj[index] = type.string_to_value(value)
    end

    def [](key)
      @options[key]
    end
  end
end

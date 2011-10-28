module Rumx
  class Attribute
    attr_reader :name, :type, :description, :allow_read, :allow_write

    def initialize(name, type_name, description, allow_read, allow_write)
      @name        = name.to_sym
      @type        = Type.find(type_name)
      @description = description
      @allow_read  = allow_read
      @allow_write = allow_write
    end

    def get_value(bean)
      bean.send(self.name)
    end

    def set_value(bean, value)
      bean.send(self.name.to_s+'=', type.convert(value))
    end
  end
end

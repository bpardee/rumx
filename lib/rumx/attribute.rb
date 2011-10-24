module Rumx
  class Attribute
    attr_reader :name, :type, :description, :allow_read, :allow_write

    def initialize(name, type, description, allow_read, allow_write)
      @name        = name
      @type        = type
      @description = description
      @allow_read  = allow_read
      @allow_write = allow_write
    end
  end
end

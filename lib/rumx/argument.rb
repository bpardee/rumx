module Rumx
  class Argument
    attr_reader :name, :type, :description, :default_value

    def initialize(name, type_name, description, default_value=nil)
      @name          = name.to_sym
      @type          = Type.find(type_name)
      @description   = description
      @default_value = default_value
    end
  end
end

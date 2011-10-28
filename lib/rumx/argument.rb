module Rumx
  class Argument
    attr_reader :name, :type, :description

    def initialize(name, type_name, description)
      @name        = name.to_sym
      @type        = Type.find(type_name)
      @description = description
    end
  end
end

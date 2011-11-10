module Rumx
  class Operation
    attr_reader :name, :type, :description, :arguments

    def initialize(name, type_name, description, arguments)
      @name        = name.to_sym
      @type        = Type.find(type_name)
      @description = description
      @arguments   = arguments
    end

    def run(bean, argument_hash)
      args = @arguments.map do |argument|
        if argument_hash.has_key?(argument.name)
          value = argument_hash[argument.name]
        elsif argument_hash.has_key?(argument.name.to_s)
          value = argument_hash[argument.name.to_s]
        else
          raise "No value for argument #{argument.name}"
        end
        argument.type.string_to_value(value)
      end
      bean.send(self.name, *args)
    end
  end
end

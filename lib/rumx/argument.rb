module Rumx
  class Argument
    attr_reader :name, :type, :description, :default_value

    def initialize(name, type_name, description, default_value=nil)
      @name          = name.to_sym
      @type          = Type.find(type_name)
      @description   = description
      @default_value = default_value
    end

    def to_hash
      {
          'name'          => @name,
          'type'          => @type.to_s,
          'description'   => @description,
          'default_value' => @default_value
      }
    end

    def self.from_hash(hash)
      type = Type.find(hash['type'])
      default_value = type.string_to_value(hash['default_value'])
      new(hash['name'], hash['type'], hash['description'], default_value)
    end
  end
end

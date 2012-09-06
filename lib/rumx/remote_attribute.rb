module Rumx
  class RemoteAttribute < Attribute

    def initialize(name, type, description, allow_read, allow_write, options, value)
      super(name, type, description, allow_read, allow_write, options)
      @value = value
    end

    def get_value(bean)
      @value
    end

    def each_attribute_info(bean, ancestry, &block)
      child_ancestry = ancestry + [@name]
      if @value.kind_of?(Hash)
        index = child_ancestry.size
        @value.each do |name, value|
          child_ancestry[index] = name
          yield AttributeInfo.new(self, bean, child_ancestry, value)
        end
      elsif @value.kind_of?(Array)
        index = child_ancestry.size
        @value.each_with_index do |value, i|
          child_ancestry[index] = i
          yield AttributeInfo.new(self, bean, child_ancestry, value)
        end
      else
        yield AttributeInfo.new(self, bean, child_ancestry, @value)
      end
    end

    def write?(bean, params)
      param_value(params) do |value|
        @value = @type.string_to_value(value)
      end
      return false
    end

    # Partner to Attribute#to_remote_hash(bean)
    def self.from_hash(hash)
      type = Type.find(hash['type'])
      value = type.string_to_value(hash['value'])
      new(hash['name'], type, hash['description'], hash['allow_read'], hash['allow_write'], hash['options'], value)
    end
  end
end

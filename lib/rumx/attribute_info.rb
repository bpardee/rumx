module Rumx
  class AttributeInfo
    attr_reader :attribute, :bean, :ancestry, :value

    def initialize(attribute, bean, ancestry, value)
      @attribute = attribute
      @bean      = bean
      @ancestry  = ancestry
      @value     = value
    end

    def value_to_s
      @attribute.type.value_to_string(@value)
    end
  end
end

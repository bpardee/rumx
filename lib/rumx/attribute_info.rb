module Rumx
  class AttributeInfo
    attr_reader :attribute, :bean, :ancestry, :value

    def initialize(attribute, bean, ancestry, value)
      @attribute = attribute
      @bean      = bean
      @ancestry  = ancestry
      @value     = value
    end
  end
end

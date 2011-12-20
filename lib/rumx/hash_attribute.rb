module Rumx
  class HashAttribute < Attribute

    def initialize(name, type, description, allow_read, allow_write, options)
      super
      raise 'Hash attribute called without hash_type option' unless options[:hash_type]
      @hash_type = Type.find(options[:hash_type])
    end

    def each_attribute_info(bean, ancestry, &block)
      hash = bean.send(name)
      child_ancestry = ancestry+[name]
      index_index = child_ancestry.size
      hash.each do |name, value|
        value = nil unless allow_read
        child_ancestry[index_index] = name
        yield AttributeInfo.new(self, bean, child_ancestry, value)
      end
    end

    def write?(bean, params)
      return false unless params.kind_of?(Hash)
      is_written = false
      if allow_write
        hash = bean.send(name)
        return false unless hash
        params.each do |name, value|
          hash[name.to_sym] = @hash_type.string_to_value(value)
          is_written = true
        end
      end
      return is_written
    end
  end
end

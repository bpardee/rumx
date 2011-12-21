module Rumx
  class ListAttribute < Attribute

    # options
    #   list_type - any of the available types (required)
    #   max_size  - max size of the list, can be a symbol representing a method or an integer (defaults to the current size of the list)
    def initialize(name, type, description, allow_read, allow_write, options)
      super
      raise 'List attribute called without list_type option' unless options[:list_type]
      @list_type = Type.find(options[:list_type])
    end

    def each_attribute_info(bean, ancestry, &block)
      list = bean.send(name)
      child_ancestry = ancestry+[name]
      index_index = child_ancestry.size
      list.each_with_index do |value, i|
        value = nil unless allow_read
        child_ancestry[index_index] = i
        yield AttributeInfo.new(self, bean, child_ancestry, value)
      end
    end

    def write?(bean, params)
      #puts "list write params=#{params.inspect}"
      is_written = false
      if allow_write
        list = bean.send(name)
        return false unless list
        max_size = self[:max_size]
        if max_size
          if max_size.kind_of?(Symbol)
            max_size = bean.send(max_size)
          end
        else
          # Default to current size of the list if unset
          max_size = obj.size
        end
        param_value(params) do |sub_params|
          each_param(sub_params) do |index, value|
            if index < max_size
              list[index] = @list_type.string_to_value(value)
              is_written = true
            end
          end
        end
      end
      return is_written
    end

    private

    def each_param(params, &block)
      if params.kind_of?(Hash)
        params.each do |index, value|
          yield index.to_i, value
        end
      elsif params.kind_of?(Array)
        params.each_with_index do |value, index|
          yield index, value
        end
      end
    end
  end
end

module Rumx
  class ListBean
    include Bean

    def initialize(list)
      @list = list
    end

    # Find the bean
    def bean_find(name_array, index = 0)
      return self if index == name_array.size
      name = name_array[index]
      return nil unless name.match(/^\d+$/)
      child = @list[name.to_i]
      return nil unless child
      return child.bean_find(name_array, index+1)
    end

    def bean_each_embedded_child(&block)
      @list.each_with_index do |child, i|
        yield i, child
      end
    end

    protected

    def do_bean_get_attributes(ancestry, &block)
      return do_bean_get_attributes_json unless block_given?
      child_ancestry = ancestry.dup
      # Save some object creation
      child_index = child_ancestry.size
      @list.each_with_index do |bean, i|
        child_ancestry[child_index] = i
        bean.bean_get_attributes(child_ancestry, &block)
      end
    end

    def do_bean_get_attributes_json
      @list.map { |bean| bean.bean_get_attributes }
    end

    def do_bean_set_attributes(params)
      return if !params || params.empty?
      changed = false
      @list.each_with_index do |bean, i|
        changed = true
        bean.bean_set_attributes(params[i] || params[i.to_s])
      end
      bean_attributes_changed if changed
    end
  end
end

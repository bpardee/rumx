module Rumx
  class HashBean
    include Bean

    def initialize(hash)
      @hash = hash
    end

    # Find the bean
    def bean_find(name_array, index = 0)
      return self if index == name_array.size
      name = name_array[index].to_s
      child = @hash[name] || @hash[name.to_sym]
      return nil unless child
      return child.bean_find(name_array, index+1)
    end

    def bean_each_embedded_child(&block)
      @hash.each do |name, child|
        yield name, child
      end
    end

    protected

    def do_bean_get_attributes(ancestry, &block)
      return do_bean_get_attributes_json unless block_given?
      child_ancestry = ancestry.dup
      # Save some object creation
      child_index = child_ancestry.size
      @hash.each do |name, bean|
        child_ancestry[child_index] = name
        bean.bean_get_attributes(child_ancestry, &block)
      end
    end

    def do_bean_get_attributes_json
      json_hash = {}
      @hash.each do |name, bean|
        json_hash[name] = bean.bean_get_attributes
      end
      return json_hash
    end

    def do_bean_set_attributes(params)
      return if !params || params.empty?
      changed = false
      @hash.each do |name, bean|
        changed = true
        bean.bean_set_attributes(params[name] || params[name.to_sym])
      end
      bean_attributes_changed if changed
    end
  end
end

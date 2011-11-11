module Rumx
  # Defines a Rumx bean that allows access to the defined attributes and operations.
  # All public instance methods are prefixed with "bean_" to try to avoid collisions.
  module Bean
    module ClassMethods

      def bean_reader(name, type, description, options={})
        bean_add_attribute(Attribute.new(name, type, description, true, false, options))
      end

      # options
      #   max_size - the max size the list can be indexed for setting.  Can be an integer or
      #     a symbol that represents an attribute or method of the bean.  Defaults to the
      #     current size of the list.
      def bean_list_reader(name, type, description, options={})
        bean_add_list_attribute(Attribute.new(name, type, description, true, false, options))
      end

      def bean_attr_reader(name, type, description, options={})
        attr_reader(name)
        bean_reader(name, type, description, options)
      end

      def bean_list_attr_reader(name, type, description, options={})
        attr_reader(name)
        bean_list_reader(name, type, description, options)
      end

      def bean_writer(name, type, description, options={})
        bean_add_attribute(Attribute.new(name, type, description, false, true, options))
      end

      def bean_list_writer(name, type, description, options={})
        bean_add_list_attribute(Attribute.new(name, type, description, false, true, options))
      end

      def bean_attr_writer(name, type, description, options={})
        attr_writer(name)
        bean_writer(name, type, description, options)
      end

      def bean_list_attr_writer(name, type, description, options={})
        attr_writer(name)
        bean_list_writer(name, type, description, options)
      end

      def bean_accessor(name, type, description, options={})
        bean_add_attribute(Attribute.new(name, type, description, true, true, options))
      end

      def bean_list_accessor(name, type, description, options={})
        bean_add_list_attribute(Attribute.new(name, type, description, true, true, options))
      end

      def bean_attr_accessor(name, type, description, options={})
        attr_accessor(name)
        bean_accessor(name, type, description, options)
      end

      def bean_list_attr_accessor(name, type, description, options={})
        attr_accessor(name)
        bean_list_accessor(name, type, description, options)
      end

      def bean_embed(name, description)
        # We're going to ignore description (for now)
        bean_embeds << name.to_sym
      end
      
      def bean_attr_embed(name, description)
        attr_reader(name)
        bean_embed(name, description)
      end

      def bean_embed_list(name, description)
        # We're going to ignore description (for now)
        bean_embed_lists << name.to_sym
      end

      def bean_attr_embed_list(name, description)
        attr_reader(name)
        bean_embed_list(name, description)
      end

      #bean_operation     :my_operation,       :string,  'My operation', [
      #    [ :arg_int,    :int,    'An int argument'   ],
      #    [ :arg_float,  :float,  'A float argument'  ],
      #    [ :arg_string, :string, 'A string argument' ]
      #]
      def bean_operation(name, type, description, args)
        arguments = args.map do |arg|
          raise 'Invalid bean_operation format' unless arg.kind_of?(Array) && arg.size == 3
          Argument.new(*arg)
        end
        @operations ||= []
        @operations << Operation.new(name, type, description, arguments)
      end

      #######
      # private - TODO: Local helper methods, how should I designate them as private or just nodoc them?
      #######
      
      def bean_add_attribute(attribute)
        @attributes ||= []
        @attributes << attribute
      end

      def bean_add_list_attribute(attribute)
        @list_attributes ||= []
        @list_attributes << attribute
      end

      def bean_attributes
        attributes = []
        self.ancestors.reverse_each do |mod|
          attributes += mod.bean_attributes_local if mod.include?(Rumx::Bean)
        end
        return attributes
      end

      def bean_list_attributes
        attributes = []
        self.ancestors.reverse_each do |mod|
          attributes += mod.bean_list_attributes_local if mod.include?(Rumx::Bean)
        end
        return attributes
      end

      def bean_attributes_local
        @attributes ||= []
      end

      def bean_list_attributes_local
        @list_attributes ||= []
      end

      def bean_operations
        operations = []
        self.ancestors.reverse_each do |mod|
          operations += mod.bean_operations_local if mod.include?(Rumx::Bean)
        end
        return operations
      end

      def bean_operations_local
        @operations ||= []
      end

      def bean_embeds
        @embeds ||= []
      end

      def bean_embed_lists
        @embed_lists ||= []
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    def self.root
      @root ||= Beans::Folder.new
    end

    def self.find(name_array)
      bean = root
      until name_array.empty?
        name = name_array.shift.to_sym
        child_bean = bean.bean_children[name]
        if !child_bean && bean.class.bean_embeds.include?(name)
          child_bean = bean.send(name)
        end
        if !child_bean && bean.class.bean_embed_lists.include?(name)
          list = bean.send(name)
          if list
            index = name_array.shift
            child_bean = list[index.to_i] if index && index.match(/\d+/)
          end
        end
        return nil unless child_bean
        bean = child_bean
      end
      return bean
    end

    # Return [bean, attribute, param_name, value] list or nil if not found
    def self.find_attribute(name_array)
      name = name_array.pop
      # If it's a list attribute
      if name.match(/^\d+$/)
        index = name.to_i
        name = name_array.pop
        bean = Bean.find(name_array)
        return nil unless bean
        name = name.to_sym
        bean.class.bean_list_attributes.each do |attribute|
          if name == attribute.name
            obj = bean.send(attribute.name)
            if obj
              param_name = "#{attribute.name}[#{index}]"
              return [bean, attribute, param_name, attribute.get_index_value(obj, index)]
            end
          end
        end
      # else just a regular attribute
      else
        bean = Bean.find(name_array)
        return nil unless bean
        name = name.to_sym
        bean.class.bean_attributes.each do |attribute|
          if name == attribute.name
            return [bean, attribute, attribute.name, attribute.get_value(bean)]
          end
        end
      end
      return nil
    end

    # Return [bean, operation] pair or nil if not found
    def self.find_operation(name_array)
      name = name_array.pop
      bean = Bean.find(name_array)
      return nil unless bean
      name = name.to_sym
      bean.class.bean_operations.each do |operation|
        return [bean, operation] if name == operation.name
      end
      return nil
    end

    # Mutex for synchronization of attributes/operations
    def bean_mutex
      # TBD: How to initialize this in a module and avoid race condition?
      @mutex || Mutex.new
    end

    # Synchronize access to attributes and operations
    def bean_synchronize
      bean_mutex.synchronize do
        yield
      end
    end

    def bean_children
      @bean_children ||= {}
    end

    def bean_add_child(name, child_bean)
      # TBD - Should I mutex protect this?  All beans would normally be registered during the code initialization process
      raise "Error trying to add #{name} to embedded bean" if @bean_is_embedded
      bean_children[name.to_sym] = child_bean
    end

    def bean_remove_child(name)
      bean_children.delete(name.to_sym)
    end

    def bean_has_attributes?
      return true unless self.class.bean_attributes.empty? && self.class.bean_list_attributes.empty?
      self.class.bean_embeds.each do |name|
        bean = send(name)
        return true if bean && bean.bean_has_attributes?
      end
      self.class.bean_embed_lists.each do |list_name|
        list = send(list_name)
        if list 
          list.each do |bean|
            return true if bean.bean_has_attributes?
          end
        end
      end
      return false
    end

    def bean_get_attributes(rel_path=nil, param_name=nil, &block)
      bean_synchronize do
        do_bean_get_attributes(rel_path, param_name, &block)
      end
    end

    def bean_set_attributes(params)
      bean_synchronize do
        do_bean_set_attributes(params)
      end
    end

    def bean_get_and_set_attributes(params, rel_path=nil, param_name=nil, &block)
      bean_synchronize do
        val = do_bean_get_attributes(rel_path, param_name, &block)
        do_bean_set_attributes(params)
        val
      end
    end

    def bean_set_and_get_attributes(params, rel_path=nil, param_name=nil, &block)
      bean_synchronize do
        do_bean_set_attributes(params)
        do_bean_get_attributes(rel_path, param_name, &block)
      end
    end

    def bean_has_operations?
      return true unless self.class.bean_operations.empty?
      self.class.bean_embeds.each do |name|
        bean = send(name)
        return true if bean && bean.bean_has_operations?
      end
      self.class.bean_embed_lists.each do |list_name|
        list = send(list_name)
        if list 
          list.each do |bean|
            return true if bean.bean_has_operations?
          end
        end
      end
      return false
    end

    def bean_each_operation(rel_path=nil, &block)
      self.class.bean_operations.each do |operation|
        yield operation, bean_join_rel_path(rel_path, operation.name.to_s)
      end
      self.class.bean_embeds.each do |name|
        bean = send(name)
        bean.bean_each_operation(bean_join_rel_path(rel_path, name), &block) if bean
      end
      self.class.bean_embed_lists.each do |name|
        list = send(name)
        if list 
          list_rel_path = bean_join_rel_path(rel_path, name)
          list.each_with_index do |bean, i|
            bean.bean_each_operation(bean_join_rel_path(list_rel_path, i.to_s), &block)
          end
        end
      end
    end

    #########
    protected
    #########

    # Allow extenders to save changes, etc. if attribute values change
    def bean_attributes_changed
    end

    #######
    private
    #######

    # Separate call in case we're already mutex locked
    def do_bean_get_attributes(rel_path, param_name, &block)
      return do_bean_get_attributes_json unless block_given?
      self.class.bean_attributes.each do |attribute|
        yield attribute, attribute.get_value(self), bean_join_rel_path(rel_path, attribute.name.to_s), bean_join_param_name(param_name, attribute.name.to_s)
      end
      self.class.bean_list_attributes.each do |attribute|
        obj = send(attribute.name)
        if obj
          new_rel_path   = bean_join_rel_path(rel_path, attribute.name.to_s)
          new_param_name = bean_join_param_name(param_name, attribute.name.to_s)
          obj.each_index do |i|
            yield attribute, attribute.get_index_value(obj, i), "#{new_rel_path}/#{i}", "#{new_param_name}[#{i}]"
          end
        end
      end
      self.class.bean_embeds.each do |name|
        bean = send(name)
        bean.bean_get_attributes(bean_join_rel_path(rel_path, name), bean_join_param_name(param_name, name), &block) if bean
      end
      self.class.bean_embed_lists.each do |name|
        list = send(name)
        if list 
          list_rel_path   = bean_join_rel_path(rel_path, name)
          list_param_name = bean_join_param_name(param_name, name)
          list.each_with_index do |bean, i|
            bean.bean_get_attributes(bean_join_rel_path(list_rel_path, i.to_s), bean_join_param_name(list_param_name, i.to_s), &block)
          end
        end
      end
    end

    def do_bean_get_attributes_json
      hash = {}
      self.class.bean_attributes.each do |attribute|
        hash[attribute.name] = attribute.get_value(self)
      end
      self.class.bean_list_attributes.each do |attribute|
        hash[attribute.name] = attribute.get_value(self)
      end
      self.class.bean_embeds.each do |name|
        bean = send(name)
        hash[name] = bean.bean_get_attributes if bean
      end
      self.class.bean_embed_lists.each do |name|
        list = send(name)
        if list 
          hash[name] = list.map {|bean| bean.bean_get_attributes}
        end
      end
      return hash
    end

    # Separate call in case we're already mutex locked
    def do_bean_set_attributes(params)
      return if !params || params.empty?
      changed = false
      self.class.bean_attributes.each do |attribute|
        if attribute.allow_write
          if params.has_key?(attribute.name)
            attribute.set_value(self, params[attribute.name])
            changed = true
          elsif params.has_key?(attribute.name.to_s)
            attribute.set_value(self, params[attribute.name.to_s])
            changed = true
          end
        end
      end
      self.class.bean_list_attributes.each do |attribute|
        if attribute.allow_write
          obj = send(attribute.name)
          sub_params = params[attribute.name] || params[attribute.name.to_s]
          raise "Can't assign value for nil list attribute" if !obj && sub_params
          if sub_params
            # TODO: Allow array?
            raise "Invalid param for #{attribute.name}" unless sub_params.kind_of?(Hash)
            max_size = attribute[:max_size]
            if max_size
              if max_size.kind_of?(Symbol)
                max_size = send(max_size)
              end
            else
              # Default to current size of the list if unset
              max_size = obj.size
            end
            sub_params.each do |index, value|
              if index.to_i < max_size
                attribute.set_index_value(obj, index.to_i, value)
                changed = true
              end
            end
          end
        end
      end
      self.class.bean_embeds.each do |name|
        bean = send(name)
        if bean
          embedded_params = params[name]
          bean.bean_set_attributes(embedded_params)
          changed = true
        end
      end
      self.class.bean_embed_lists.each do |name|
        list = send(name)
        if list 
          list_params = params[name]
          if list_params
            list.each_with_index do |bean, i|
              bean.bean_set_attributes(list_params[i] || list_params[i.to_s])
            end
            changed = true
          end
        end
      end
      bean_attributes_changed if changed
    end

    def bean_join_rel_path(parent_rel_path, name)
      if parent_rel_path
        "#{parent_rel_path}/#{name}"
      else
        name.to_s
      end
    end

    def bean_join_param_name(parent_param_name, name)
      if parent_param_name
        "#{parent_param_name}[#{name}]"
      else
        name.to_s
      end
    end
  end
end

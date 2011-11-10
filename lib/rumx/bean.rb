module Rumx
  # Defines a Rumx bean that allows access to the defined attributes and operations.
  # All public instance methods are prefixed with "bean_" to try to avoid collisions.
  module Bean
    module ClassMethods

      def bean_reader(name, type, description)
        bean_add_attribute(Attribute.new(name, type, description, true, false))
      end

      def bean_list_reader(name, type, description)
        bean_add_list_attribute(Attribute.new(name, type, description, true, false))
      end

      def bean_attr_reader(name, type, description)
        attr_reader(name)
        bean_reader(name, type, description)
      end

      def bean_list_attr_reader(name, type, description)
        attr_reader(name)
        bean_list_reader(name, type, description)
      end

      def bean_writer(name, type, description)
        bean_add_attribute(Attribute.new(name, type, description, false, true))
      end

      def bean_list_writer(name, type, description)
        bean_add_list_attribute(Attribute.new(name, type, description, false, true))
      end

      def bean_attr_writer(name, type, description)
        attr_writer(name)
        bean_writer(name, type, description)
      end

      def bean_list_attr_writer(name, type, description)
        attr_writer(name)
        bean_list_writer(name, type, description)
      end

      def bean_accessor(name, type, description)
        bean_add_attribute(Attribute.new(name, type, description, true, true))
      end

      def bean_list_accessor(name, type, description)
        bean_add_list_attribute(Attribute.new(name, type, description, true, true))
      end

      def bean_attr_accessor(name, type, description)
        attr_accessor(name)
        bean_accessor(name, type, description)
      end

      def bean_list_attr_accessor(name, type, description)
        attr_accessor(name)
        bean_list_accessor(name, type, description)
      end

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
        name = name_array.shift
        child_bean = bean.bean_children[name] || bean.bean_embedded_children[name]
        unless child_bean
          list = bean.bean_embedded_child_lists[name]
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
      oper_name = name_array.pop
      bean = Bean.find(name_array)
      return nil unless bean
      operation = bean.bean_find_operation(oper_name)
      return nil unless operation
      return [bean, operation]
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
      bean_children[name.to_s] = child_bean
    end

    def bean_remove_child(name)
      bean_children.delete(name.to_s)
    end

    def bean_embedded_children
      @bean_embedded_children ||= {}
    end

    def bean_add_embedded_child(name, embedded_child_bean)
      raise "Error trying to add bean #{name} as embedded, it already has children" unless embedded_child_bean.bean_children.empty?
      embedded_child_bean.instance_variable_set('@bean_is_embedded', true)
      bean_embedded_children[name.to_s] = embedded_child_bean
    end

    def bean_remove_embedded_child(name)
      bean_embedded_children.delete(name.to_s)
    end

    def bean_embedded_child_lists
      @bean_embedded_child_lists ||= {}
    end

    def bean_add_embedded_child_list(name, embedded_child_list)
      bean_embedded_child_lists[name.to_s] = embedded_child_list
    end

    def bean_remove_embedded_child_list(name)
      bean_embedded_child_lists.delete(name.to_s)
    end

    def bean_find_operation(name)
      name = name.to_sym
      self.class.bean_operations.each do |operation|
        return operation if name == operation.name
      end
      return nil
    end

    def bean_has_attributes?
      return true unless self.class.bean_attributes.empty? && self.class.bean_list_attributes.empty?
      bean_embedded_children.each_value do |bean|
        return true if bean.bean_has_attributes?
      end
      bean_embedded_child_lists.each_value do |list|
        list.each do |bean|
          return true if bean.bean_has_attributes?
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
      bean_embedded_children.each_value do |bean|
        return true if bean.bean_has_operations?
      end
      bean_embedded_child_lists.each_value do |list|
        list.each do |bean|
          return true if bean.bean_has_operations?
        end
      end
      return false
    end

    def bean_each_operation(rel_path=nil, &block)
      self.class.bean_operations.each do |operation|
        yield operation, join_rel_path(rel_path, operation.name.to_s)
      end
      bean_embedded_children.each do |name, bean|
        bean.bean_each_operation(join_rel_path(rel_path, name), &block)
      end
      bean_embedded_child_lists.each do |name, list|
        list_rel_path   = join_rel_path(rel_path, name)
        list.each_with_index do |bean, i|
          bean.bean_each_operation(join_rel_path(list_rel_path, i.to_s), &block)
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
        yield attribute, attribute.get_value(self), join_rel_path(rel_path, attribute.name.to_s), join_param_name(param_name, attribute.name.to_s)
      end
      self.class.bean_list_attributes.each do |attribute|
        obj = send(attribute.name)
        if obj
          new_rel_path   = join_rel_path(rel_path, attribute.name.to_s)
          new_param_name = join_param_name(param_name, attribute.name.to_s)
          obj.each_index do |i|
            yield attribute, attribute.get_index_value(obj, i), "#{new_rel_path}/#{i}", "#{new_param_name}[#{i}]"
          end
        end
      end
      bean_embedded_children.each do |name, bean|
        bean.bean_get_attributes(join_rel_path(rel_path, name), join_param_name(param_name, name), &block)
      end
      bean_embedded_child_lists.each do |name, list|
        list_rel_path   = join_rel_path(rel_path, name)
        list_param_name = join_param_name(param_name, name)
        list.each_with_index do |bean, i|
          bean.bean_get_attributes(join_rel_path(list_rel_path, i.to_s), join_param_name(list_param_name, i.to_s), &block)
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
      bean_embedded_children.each do |name, bean|
        hash[name] = bean.bean_get_attributes
      end
      bean_embedded_child_lists.each do |name, list|
        hash[name] = list.map {|bean| bean.bean_get_attributes}
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
            raise "Invalid param for #{attribute.name}" unless sub_params.kind_of?(Hash)
            sub_params.each do |index, value|
              attribute.set_index_value(obj, index.to_i, value)
              changed = true
            end
          end
        end
      end
      bean_embedded_children.each do |name, bean|
        embedded_params = params[name]
        bean.bean_set_attributes(embedded_params)
      end
      bean_embedded_child_lists.each do |name, list|
        list_params = params[name]
        if list_params
          list.each_with_index do |bean, i|
            bean.bean_set_attributes(list_params[i] || list_params[i.to_s])
          end
        end
      end
      bean_attributes_changed if changed
    end

    def join_rel_path(old_rel_path, name)
      if old_rel_path
        old_rel_path + '/' + name
      else
        name
      end
    end

    def join_param_name(old_param_name, name)
      if old_param_name
        old_param_name + '[' + name + ']'
      else
        name
      end
    end
  end
end

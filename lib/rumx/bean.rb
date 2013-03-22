require 'monitor'

module Rumx
  # Defines a Rumx bean that allows access to the defined attributes and operations.
  # All public instance methods are prefixed with "bean_" to try to avoid collisions.
  module Bean
    @@root_hash = {}

    module ClassMethods

      # options
      #   type => :list
      #     list_type - type of each list element
      #     max_size - the max size the list can be indexed for setting.  Can be an integer or
      #       a symbol that represents an attribute or method of the bean.  Defaults to the
      #       current size of the list.
      def bean_reader(name, type, description, options={})
        bean_add_attribute(name, type, description, true, false, options)
      end

      def bean_list_reader(name, type, description, options={})
        raise "bean_list_reader no longer used, instead use 'bean_reader :#{name}, :list, #{description.inspect}, #{options.merge(:list_type => type).inspect}'"
      end

      def bean_attr_reader(name, type, description, options={})
        attr_reader(name)
        bean_reader(name, type, description, options)
      end

      def bean_list_attr_reader(name, type, description, options={})
        raise "bean_list_attr_reader no longer used, instead use 'bean_attr_reader :#{name}, :list, #{description.inspect}, #{options.merge(:list_type => type).inspect}'"
      end

      def bean_writer(name, type, description, options={})
        bean_add_attribute(name, type, description, false, true, options)
      end

      def bean_list_writer(name, type, description, options={})
        raise "bean_list_writer no longer used, instead use 'bean_writer :#{name}, :list, #{description.inspect}, #{options.merge(:list_type => type).inspect}'"
      end

      def bean_attr_writer(name, type, description, options={})
        attr_writer(name)
        bean_writer(name, type, description, options)
      end

      def bean_list_attr_writer(name, type, description, options={})
        raise "bean_list_attr_writer no longer used, instead use 'bean_attr_writer :#{name}, :list, #{description.inspect}, #{options.merge(:list_type => type).inspect}'"
      end

      def bean_accessor(name, type, description, options={})
        bean_add_attribute(name, type, description, true, true, options)
      end

      def bean_list_accessor(name, type, description, options={})
        raise "bean_list_accessor no longer used, instead use 'bean_accessor :#{name}, :list, #{description.inspect}, #{options.merge(:list_type => type).inspect}'"
      end

      def bean_attr_accessor(name, type, description, options={})
        attr_accessor(name)
        bean_accessor(name, type, description, options)
      end

      def bean_list_attr_accessor(name, type, description, options={})
        raise "bean_list_attr_accessor no longer used, instead use 'bean_attr_accessor :#{name}, :list, #{description.inspect}, #{options.merge(:list_type => type).inspect}'"
      end

      def bean_embed(name, description)
        raise "bean_embed no longer used, instead use 'bean_reader :#{name}, :bean, #{description.inspect}'"
      end
      
      def bean_attr_embed(name, description)
        raise "bean_attr_embed no longer used, instead use 'bean_attr_reader :#{name}, :bean, #{description.inspect}'"
      end

      def bean_embed_list(name, description)
        raise "bean_embed_list no longer used, instead use 'bean_attr_reader :#{name}, :list, #{description.inspect}, :list_type => :bean'"
      end

      def bean_attr_embed_list(name, description)
        raise "bean_attr_embed_list no longer used, instead use 'bean_attr_reader :#{name}, :list, #{description.inspect}, :list_type => :bean'"
      end

      #bean_operation     :my_operation,       :string,  'My operation', [
      #    [ :arg_int,    :integer, 'An int argument'   ],
      #    [ :arg_float,  :float,   'A float argument'  ],
      #    [ :arg_string, :string,  'A string argument' ]
      #]
      def bean_operation(name, type, description, args)
        name = name.to_sym
        arguments = args.map do |arg|
          raise 'Invalid bean_operation format' unless arg.kind_of?(Array) && (arg.size == 3 || arg.size == 4)
          Argument.new(*arg)
        end
        bean_operations_local[name] = Operation.new(name, type, description, arguments)
      end

      #######
      # private - TODO: Local helper methods, how should I designate them as private or just nodoc them?
      #######
      
      def bean_add_attribute(name, type_name, description, allow_read, allow_write, options)
        # Dummy up the things that are defined like attributes but are really beans
        name = name.to_sym
        if type_name == :bean
          bean_embeds_local[name] = nil
        elsif type_name == :list && options[:list_type] == :bean
          bean_embeds_local[name] = ListBean
        elsif type_name == :hash && options[:hash_type] == :bean
          bean_embeds_local[name] = HashBean
        else
          type = Type.find(type_name)
          bean_attributes_local[name] = type.create_attribute(name, description, allow_read, allow_write, options)
        end
      end

      def bean_attributes
        attributes = []
        self.ancestors.reverse_each do |mod|
          attributes += mod.bean_attributes_local.values if mod.include?(Rumx::Bean)
        end
        return attributes
      end

      def bean_attributes_local
        @attributes ||= {}
      end

      def bean_operations
        operations = []
        self.ancestors.reverse_each do |mod|
          operations += mod.bean_operations_local.values if mod.include?(Rumx::Bean)
        end
        return operations
      end

      def bean_operations_local
        @operations ||= {}
      end

      def bean_embeds
        embeds = {}
        # Merge in all the module embeds that are beans
        self.ancestors.reverse_each do |mod|
          embeds = embeds.merge(mod.bean_embeds_local) if mod.include?(Rumx::Bean)
        end
        return embeds
      end

      def bean_embeds_local
        @embeds ||= {}
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    def self.add_root(name, bean)
      @@root_hash[name.to_sym] = bean
    end

    def self.remove_root(name)
      @@root_hash.delete(name.to_sym)
    end

    def self.root(name = nil)
      if name
        root = @@root_hash[name.to_sym]
      else
        root = @root ||= Beans::Folder.new
      end
      root.bean_root_hook if root
      return root
    end

    def self.find(name_array)
      name_array = name_array.split('/') if name_array.kind_of?(String)
      bean = root.bean_find(name_array)
      return bean if bean
      my_root = root(name_array[0])
      return nil unless my_root
      return my_root.bean_find(name_array, 1)
    end

    # Return [bean, operation] pair or nil if not found
    def self.find_operation(name_array, operation_name)
      bean = Bean.find(name_array)
      return nil unless bean
      operation = bean.bean_find_operation(operation_name)
      return nil unless operation
      return [bean, operation]
    end

    def self.run_operation(name_array, operation_name, argument_hash)
      bean, operation = Bean.find_operation(name_array, operation_name)
      return nil unless bean
      value = bean.bean_run_operation(operation, argument_hash)
      return [bean, operation, value]
    end

    # Monitor for synchronization of attributes/operations
    def bean_monitor
      # TODO: How to initialize this in a module and avoid race condition?
      @monitor ||= Monitor.new
    end

    # Synchronize access to attributes and operations
    def bean_synchronize
      bean_monitor.synchronize do
        yield
      end
    end

    def bean_children
      # TODO: How to initialize this in a module and avoid race condition?
      @bean_children ||= {}
    end

    def bean_add_child(name, child_bean)
      bean_synchronize do
        bean_children[name.to_sym] = child_bean
      end
    end

    def bean_remove_child(name)
      bean_synchronize do
        bean_children.delete(name.to_sym)
      end
    end

    # Allow remote roots to update all their children
    def bean_reset_children(new_bean_children)
      bean_synchronize do
        @bean_children = new_bean_children
      end
    end

    # Find the bean
    def bean_find(name_array, index = 0)
      return self if index == name_array.size
      name = name_array[index].to_sym
      child_bean = bean_children[name] || bean_embedded(name)
      return nil unless child_bean
      return child_bean.bean_find(name_array, index+1)
    end

    def bean_each(ancestry=[], &block)
      yield self, ancestry
      bean_each_child_recursive(ancestry) do |child_bean, child_ancestry|
        yield child_bean, child_ancestry
      end
    end

    def bean_each_child_recursive(ancestry, &block)
      child_ancestry = ancestry.dup
      # Save some object creation
      child_index = child_ancestry.size
      bean_each_child do |name, bean|
        child_ancestry[child_index] = name
        bean.bean_each(child_ancestry, &block)
      end
    end

    # Call the block for each direct child of this bean (includes the bean_children and the embedded beans)
    def bean_each_child(&block)
      bean_children.each do |name, bean|
        yield name, bean
      end
      bean_each_embedded_child do |name, bean|
        yield name, bean
      end
    end

    # Call the block for all the embedded beans
    def bean_each_embedded_child(&block)
      self.class.bean_embeds.each do |name, bean_klass|
        bean = send(name)
        if bean
          # bean_klass is either ListBean or HashBean, otherwise we already have our bean
          bean = bean_klass.new(bean) if bean_klass
          yield name, bean
        end
      end
    end

    def bean_embedded(name)
      return nil unless self.class.bean_embeds.key?(name)
      bean = send(name)
      if bean
        bean_klass = self.class.bean_embeds[name]
        bean = bean_klass.new(bean) if bean_klass
      end
      return bean
    end

    def bean_find_operation(name)
      name = name.to_sym
      self.bean_operations.each do |operation|
        return operation if name == operation.name
      end
      return nil
    end

    # Return all the attributes associated with this bean.  This would typically be defined by the class
    # but can be overridden for cases such as RemoteBean.
    def bean_attributes
      self.class.bean_attributes
    end

    # Return all the operations associated with this bean.  This would typically be defined by the class
    # but can be overridden for cases such as RemoteBean.
    def bean_operations
      self.class.bean_operations
    end

    def bean_has_attributes?
      return true unless self.bean_attributes.empty?
      bean_each_embedded_child do |name, bean|
        return true if bean.bean_has_attributes?
      end
      return false
    end

    def bean_get_attributes(ancestry=[], write_only=false, &block)
      bean_synchronize do
        do_bean_get_attributes(ancestry, write_only, &block)
      end
    end

    def bean_set_attributes(params)
      bean_synchronize do
        do_bean_set_attributes(params)
      end
    end

    def bean_get_and_set_attributes(params, ancestry=[], write_only=false, &block)
      bean_synchronize do
        val = do_bean_get_attributes(ancestry, write_only, &block)
        do_bean_set_attributes(params)
        val
      end
    end

    def bean_set_and_get_attributes(params, ancestry=[], write_only=false, &block)
      bean_synchronize do
        do_bean_set_attributes(params)
        do_bean_get_attributes(ancestry, write_only=false, &block)
      end
    end

    def bean_has_operations?
      !self.bean_operations.empty?
    end

    def bean_run_operation(operation, argument_hash)
      operation.run(self, argument_hash)
    end

    def bean_to_remote_hash(recursive=true, operations=true, read_only=false, write_only=false)
      # Allow splitting of read/write attributes so that clients that updates read_only status info
      # won't get called back with their own updates
      hash = {}
      bean_synchronize do
        if recursive
          bean_hash = {}
          bean_each_child do |name, bean|
            bean_hash[name] = bean.bean_to_remote_hash(true, read_only, write_only)
          end
          hash['beans'] = bean_hash
        end
        attributes = []
        bean_attributes.each do |attribute|
          if (!read_only || attribute.allow_read) && (!write_only || attribute.allow_write)
            attributes << attribute.to_remote_hash(self)
          end
        end
        hash['attributes'] = attributes
        hash['operations'] = bean_operations.map(&:to_hash) if operations
        return hash
      end
    end

    # Hook to allow root beans to load up their children when accessed
    def bean_root_hook
    end

    #########
    protected
    #########

    # Allow extenders to save changes, etc. if attribute values change
    def bean_attributes_changed
    end

    # Separate call in case we're already monitor locked
    def do_bean_get_attributes(ancestry, write_only=false, &block)
      return do_bean_get_attributes_json(write_only) unless block_given?
      self.bean_attributes.each do |attribute|
        if !write_only || attribute.allow_write
          attribute.each_attribute_info(self, ancestry) { |attribute_info| yield attribute_info }
        end
      end
      child_ancestry = ancestry.dup
      # Save some object creation
      child_index = child_ancestry.size
      bean_each_child do |name, bean|
        child_ancestry[child_index] = name
        bean.bean_get_attributes(child_ancestry, write_only, &block)
      end
    end

    def do_bean_get_attributes_json(write_only=false)
      hash = {}
      self.bean_attributes.each do |attribute|
        hash[attribute.name] = attribute.get_value(self) if !write_only || attribute.allow_write
      end
      bean_each_child do |name, bean|
        hash[name] = bean.bean_get_attributes(write_only)
      end
      return hash
    end

    # Separate call in case we're already monitor locked
    def do_bean_set_attributes(params)
      return if !params || params.empty?
      changed = false
      self.bean_attributes.each do |attribute|
        changed = true if attribute.write?(self, params)
      end
      bean_each_child do |name, bean|
        embedded_params = params[name] || params[name.to_s]
        if embedded_params && !embedded_params.empty?
          bean.bean_set_attributes(embedded_params)
          changed = true
        end
      end
      bean_attributes_changed if changed
    end
  end
end

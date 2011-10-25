module Rumx
  module Bean
    module ClassMethods

      def bean_reader(name, type, description)
        bean_add_attribute(Attribute.new(name, type, description, true, false))
      end

      def bean_attr_reader(name, type, description)
        attr_reader(name)
        bean_reader(name, type, description)
      end

      def bean_add_attribute(attribute)
        bean_attributes << attribute
      end

      def bean_attributes
        @attributes ||= ]
      end

      def bean_operations
        @operations ||= ]
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    def self.root
      @root ||= FolderBean.new
    end

    def self.find(name_array)
      bean = root
      name_array.each do |name|
        bean = bean.bean_children[name]
        return nil unless bean
      end
      bean
    end

    #def self.get_attributes(name_array, options)
    #  bean = find(name_array)
    #  return nil unless bean
    #  hash = {}
    #  bean.class.bean_attributes.each do |name, attribute|
    #    if attribute.allow_read
    #      hash[name] = bean.send(name)
    #    end
    #  end
    #  hash
    #end
    #
    #def self.set_attributes(name_array, options)
    #  bean = find(name_array)
    #  return nil unless bean
    #  hash = {}
    #  bean.class.bean_attributes.each do |name, attribute|
    #    if attribute.allow_write && value = options[name]
    #      bean.send(name+'=', value)
    #    end
    #  end
    #  hash
    #end
    
    #def self.get(name_array, options)
    #  name = name_array.pop
    #end

    def bean_children
      @children ||= {}
    end

    def bean_register_child(name, child_bean)
      # TBD - Should I mutex protect this?
      bean_children[name.to_s] = child_bean
    end

    def bean_each_attribute_value
      self.class.bean_attributes.each do |attribute|
        if attribute.allow_read
          yield attribute, send(attribute.name)
        end
      end
    end
  end
end

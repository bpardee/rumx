module Rumx
  class JMXBean
    include Bean

    def initialize(object_name)
      @name = javax.management.ObjectName.new(object_name)
      @mbean_info = java.lang.management.ManagementFactory.getPlatformMBeanServer.getMBeanInfo(@name)
      raise "Could not find JMX Bean matching #{object_name}" unless @mbean_info
    end

    def bean_has_attributes?
      @mbean_info.getAttributes.size > 0
    end

    protected

    def do_bean_get_attributes(ancestry, &block)
      return do_bean_get_attributes_json unless block_given?
      server = java.lang.management.ManagementFactory.getPlatformMBeanServer
      child_ancestry = ancestry.dup
      # Save some object creation
      child_index = child_ancestry.size
      @mbean_info.getAttributes.each do |mbean_attribute_info|
        type = jmx_type_to_rumx_type(mbean_attribute_info.type)
        if type
          attribute_name = mbean_attribute_info.name
          value = server.getAttribute(@name, attribute_name)
          attribute = Attribute.new(attribute_name, type, mbean_attribute_info.description, mbean_attribute_info.is_readable, mbean_attribute_info.is_writable, {})
          child_ancestry[child_index] = attribute_name
          attribute_info = AttributeInfo.new(attribute, self, child_ancestry, value)
          yield attribute_info
        end
      end
    end

    def do_bean_get_attributes_json
      hash = {}
      server = java.lang.management.ManagementFactory.getPlatformMBeanServer
      @mbean_info.getAttributes.each do |mbean_attribute_info|
        type = jmx_type_to_rumx_type(mbean_attribute_info.type)
        if type
          attribute_name = mbean_attribute_info.name
          value = server.getAttribute(@name, attribute_name)
          hash[attribute_name] = value
        end
      end
      return hash
    end

    def do_bean_set_attributes(params)
      return if !params || params.empty?
      changed = false
      server = java.lang.management.ManagementFactory.getPlatformMBeanServer
      @mbean_info.getAttributes.each do |mbean_attribute_info|
        type = jmx_type_to_rumx_type(mbean_attribute_info.type)
        if type && mbean_attribute_info.is_writable
          attribute_name = mbean_attribute_info.name
          jmx_attribute = nil
          if params.has_key?(attribute_name)
            value = type.string_to_value(params[attribute_name])
            jmx_attribute = javax.management.Attribute.new(attribute_name, value)
          elsif params.has_key?(attribute_name.to_sym)
            value = type.string_to_value(params[attribute_name.to_sym])
            jmx_attribute = javax.management.Attribute.new(attribute_name, value)
          end
          if jmx_attribute
            server.setAttribute(@name, jmx_attribute)
            changed = true
          end
        end
      end
      bean_attributes_changed if changed
    end

    def jmx_type_to_rumx_type(jmx_type)
      case jmx_type
        when 'int', 'long'
          Type.find(:integer)
        when 'float', 'double'
          Type.find(:float)
        when 'boolean'
          Type.find(:boolean)
        when 'java.lang.String'
          Type.find(:string)
        else
          nil
      end
    end
  end
end

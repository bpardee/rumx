module Rumx
  class Type
    attr_reader :name

    def self.find(type_name)
      type = @@allowed_types[type_name.to_sym]
      raise "No such type=#{type_name} in Rumx::Type" unless type
      type
    end

    def self.find_by_value(val)
      if val.kind_of?(Integer)
        @@llowed_types[:integer]
      elsif val.kind_of?(Float)
        @@llowed_types[:float]
      elsif val.kind_of?(String)
        @@llowed_types[:string]
      elsif val.kind_of?(Symbol)
        @@llowed_types[:symbol]
      elsif val.kind_of?(Boolean)
        @@llowed_types[:boolean]
      elsif val.kind_of?(Array)
        @@llowed_types[:list]
      elsif val.kind_of?(Hash)
        @@llowed_types[:hash]
      else
        nil
      end
    end

    def initialize(name, attribute_class, string_to_value_proc, value_to_string_proc=lambda{|v| v.to_s})
      @name                 = name
      @attribute_class      = attribute_class
      @string_to_value_proc = string_to_value_proc
      @value_to_string_proc = value_to_string_proc
    end

    def create_attribute(name, description, allow_read, allow_write, options)
      @attribute_class.new(name, self, description, allow_read, allow_write, options)
    end

    def string_to_value(string)
      @string_to_value_proc.call(string)
    end

    def value_to_string(val)
      @value_to_string_proc.call(val)
    end

    def to_s
      @name.to_s
    end

    def self.json_string_to_value(obj)
      obj = JSON.parse(obj) if obj.kind_of?(String)
      return obj
    end
    
    @@allowed_types = {
        :integer => new(:integer, Attribute,     lambda {|s| s.to_i}),
        :float   => new(:float,   Attribute,     lambda {|s| s.to_f}),
        :string  => new(:string,  Attribute,     lambda {|s| s.to_s}),
        :symbol  => new(:symbol,  Attribute,     lambda {|s| s.to_sym}),
        :boolean => new(:boolean, Attribute,     lambda {|s| s.to_s == 'true'}),
        :list    => new(:list,    ListAttribute, method(:json_string_to_value), lambda {|s| s.to_json}),
        :hash    => new(:hash,    HashAttribute, method(:json_string_to_value), lambda {|s| s.to_json}),
        :void    => new(:void,    nil,           lambda {|s| nil}, lambda {|v| ''})
    }

    # We've created all the instances we need
    private_class_method :new
  end
end

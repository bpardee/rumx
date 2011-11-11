module Rumx
  class Type
    attr_reader :name

    def self.find(type_name)
      type = @@allowed_types[type_name.to_sym]
      raise "No such type=#{type_name} in Rumx::Type" unless type
      type
    end

    def initialize(name, string_to_value_proc, value_to_string_proc=lambda{|v| v.to_s})
      @name = name
      @string_to_value_proc = string_to_value_proc
      @value_to_string_proc = value_to_string_proc
    end

    def string_to_value(string)
      @string_to_value_proc.call(string)
    end

    def to_s
      @name.to_s
    end

    @@allowed_types = {
        :integer => new(:integer, lambda {|s| s.to_i}),
        :float   => new(:float,   lambda {|s| s.to_f}),
        :string  => new(:string,  lambda {|s| s.to_s}),
        :boolean => new(:boolean, lambda {|s| s.to_s == 'true'}),
        :void    => new(:void,    lambda {|s| nil}, lambda {|v| ''})
    }

    # We've created all the instances we need
    private_class_method :new
  end
end

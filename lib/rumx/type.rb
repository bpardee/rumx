module Rumx
  class Type
    attr_reader :name

    def self.find(type_name)
      type = @@allowed_types[type_name.to_sym]
      raise "No such type=#{type_name} in Rumx::Type" unless type
      type
    end

    def initialize(name, convert_proc)
      @name = name
      @convert_proc = convert_proc
    end

    def convert(value)
      @convert_proc.call(value)
    end

    def to_s
      @name.to_s
    end

    @@allowed_types = {
        :integer => new(:integer, lambda {|s| s.to_i}),
        :float   => new(:float,   lambda {|s| s.to_f}),
        :string  => new(:string,  lambda {|s| s.to_s}),
        :boolean => new(:boolean, lambda {|s| s.to_s == 'true' || s.to_s == ''})
    }

    # We've created all the instances we need
    private_class_method :new
  end
end

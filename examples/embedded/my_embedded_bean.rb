require 'rumx'

class MyEmbeddedBean
  include Rumx::Bean

  bean_attr_reader   :foo, :integer, 'Foo integer'
  bean_attr_accessor :bar, :integer, 'Bar integer'

  bean_operation     :my_embedded_operation,       :string,  'My embedded_operation', [
      [ :arg_string, :string,  'A string argument' ]
  ]

  def initialize
    @foo = 2
    @bar = 3
  end
  
  def my_embedded_operation(arg_string)
    "arg_string value=#{arg_string}"
  end
end


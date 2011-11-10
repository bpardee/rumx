require 'rumx'
require 'my_embedded_bean'

class MyBean
  include Rumx::Bean

  bean_attr_accessor :greeting, :string,  'My greeting'

  bean_operation     :my_operation,       :string,  'My operation', [
      [ :arg_int,    :integer, 'An int argument'   ]
  ]

  def initialize
    @greeting      = 'Hello, Rumx'
    @embedded_bean = MyEmbeddedBean.new
    bean_add_embedded_child('EmbeddedBean', @embedded_bean)
  end

  def my_operation(arg_int)
    "arg_int value=#{arg_int}"
  end
end


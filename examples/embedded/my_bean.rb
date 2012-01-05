require 'rumx'
require './my_embedded_bean'

class MyBean
  include Rumx::Bean

  bean_attr_accessor :greeting, :string, 'My greeting'
  #old bean_attr_embed    :embedded,           'My embedded bean'
  bean_attr_reader   :embedded, :bean,   'My embedded bean'

  bean_operation     :my_operation,       :string,  'My operation', [
      [ :arg_int,    :integer, 'An int argument'   ]
  ]

  def initialize
    @greeting = 'Hello, Rumx'
    @embedded = MyEmbeddedBean.new
  end

  def my_operation(arg_int)
    "arg_int value=#{arg_int}"
  end
end


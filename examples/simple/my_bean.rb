require 'rumx'

class MyBean
  include Rumx::Bean

  bean_attr_reader   :greeting,           :string,  'My greeting'
  bean_reader        :goodbye,            :string,  'My goodbye'
  bean_attr_accessor :my_accessor,        :integer, 'My integer accessor'
  bean_attr_writer   :my_writer,          :float,   'My float writer'
  bean_reader        :readable_my_writer, :float,   'My secret access to the write-only attribute my_writer'

  bean_operation     :my_operation,       :string,  'My operation', [
      [ :arg_int,    :integer, 'An int argument'   ],
      [ :arg_float,  :float,   'A float argument'  ],
      [ :arg_string, :string,  'A string argument' ]
  ]

  def initialize
    @greeting    = 'Hello, Rumx'
    @my_accessor = 4
    @my_writer   = 10.78
  end

  def goodbye
    'Goodbye, Rumx (hic)'
  end

  def readable_my_writer
    @my_writer
  end

  def my_operation(arg_int, arg_float, arg_string)
    "arg_int class=#{arg_int.class} value=#{arg_int} arg_float class=#{arg_float.class} value=#{arg_float} arg_string class=#{arg_string.class} value=#{arg_string}"
  end
end


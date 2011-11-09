require 'rumx'

class MyEntryBean
  include Rumx::Bean

  bean_attr_accessor :my_int,    :integer, 'My integer'
  bean_attr_reader   :my_string, :string,  'My string'

  def initialize(my_int, my_string)
    @my_int, @my_string = my_int, my_string
  end
end

class MyBean
  include Rumx::Bean

  bean_attr_reader :greeting, :string, 'My greeting'

  bean_operation   :push_entry, :void, 'Push entry onto entry list', [
      [ :my_int,    :integer, 'An integer argument' ],
      [ :my_string, :string,  'A string argument' ]
  ]

  def initialize
    @greeting = 'Hello, Rumx'
    @entries = [MyEntryBean.new(1, '#1')]
    bean_add_embedded_child_list('Entries', @entries)
  end

  def push_entry(my_int, my_string)
    @entries.push(MyEntryBean.new(my_int, my_string))
  end
end


require 'rumx'

class MyBean
  include Rumx::Bean

  bean_attr_reader        :greeting, :string, 'My greeting'
  bean_list_attr_accessor :messages, :string, 'Message'

  bean_operation   :push_message, :string, 'Push message onto message list', [
      [ :message, :string, 'A string argument' ]
  ]

  def initialize
    @greeting = 'Hello, Rumx'
    @messages = ['Here', 'are', 'some messages']
  end

  def push_message(message)
    @messages.push(message)
    @messages.shift while @messages.size > 5
    return message
  end
end


require 'rumx'

class MyBean
  include Rumx::Bean

  # old bean_attr_accessor      :max_messages, :integer, 'The maximum number of messages to keep'
  bean_attr_accessor :max_messages, :integer, 'The maximum number of messages to keep'
  # old bean_list_attr_accessor :messages,     :string,  'Message', :max_size => :max_messages
  # Uncomment allow_write part to allow write access to individual messages
  bean_attr_reader :messages,     :list,    'Message', :list_type => :string, :max_size => :max_messages#, :allow_write => true

  bean_operation   :push_message, :string, 'Push message onto message list', [
      [ :message, :string, 'A string argument' ]
  ]

  def initialize
    @messages = ['Here', 'are', 'some messages']
    @max_messages = 5
  end

  def push_message(message)
    @messages.push(message)
    @messages.shift while @messages.size > @max_messages
    return message
  end

  def bean_attributes_changed
    @messages.shift while @messages.size > @max_messages
  end
end


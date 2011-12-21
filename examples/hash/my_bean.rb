require 'rumx'

class MyBean
  include Rumx::Bean

  bean_attr_reader :messages, :hash,    'Message', :hash_type => :string, :allow_write => true

  bean_operation   :put_message, :string, 'Put message onto message hash', [
      [ :key,     :symbol, 'The hash key'],
      [ :message, :string, 'The message' ]
  ]

  bean_operation   :remove_message, :string, 'Remove message from message hash', [
      [ :key,     :symbol, 'The hash key']
  ]

  def initialize
    @messages = {:foo => 'Foo message', :bar => 'Bar message'}
  end

  def put_message(key, message)
    @messages[key] = message
    return message
  end

  def remove_message(key)
    @messages.delete(key)
  end
end


require 'rumx'

class MyBean
  include Rumx::Bean

  bean_attr_reader :greeting, :string, 'My Greeting'
  bean_reader :goodbye, :string, 'My Goodbye'

  def initialize
    @greeting = 'Hello, Rumx'
  end

  def goodbye
    'Goodbye, Rumx (hic)'
  end
end


require 'rumx'

class MyOtherBean
  include Rumx::Bean

  bean_attr_accessor :message, :string, 'A message'

  def initialize
    @message = "I'm just here to put another bean in the mix"
  end
end

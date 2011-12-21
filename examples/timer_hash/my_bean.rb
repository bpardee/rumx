require 'rumx'

class MyBean
  include Rumx::Bean

  bean_attr_accessor :sleep1, :float, 'Amount of time sleep1 sleeps'
  bean_attr_accessor :sleep2, :float, 'Amount of time sleep2 sleeps'
  bean_attr_accessor :sleep3, :float, 'Amount of time sleep3 sleeps'

  def initialize
    @sleep1 = 1
    @sleep2 = 2
    @sleep3 = 3
    @timers = Rumx::Beans::TimerHash.new
    bean_add_child(:timers, @timers)
    100.times do
      Thread.new do
        while true
          @timers[:overall].measure do
            @timers[:sleep1].measure { sleep @sleep1 }
            @timers[:sleep2].measure { sleep @sleep2 }
            @timers[:sleep3].measure { sleep @sleep3 }
          end
        end
      end
    end
  end
end


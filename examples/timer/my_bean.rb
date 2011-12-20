class MyBean
  include Rumx::Bean

  bean_attr_accessor :sleep_time,      :float,   'Amount of time in seconds my measured block sleeps'
  bean_attr_accessor :percent_failure, :integer, 'Percentage of time the measured block will fail'

  def initialize
    @sleep_time      = 0.5
    @percent_failure = 10
    @timer           = Rumx::Beans::TimerAndError.new(:max_errors => 5)

    bean_add_child(:timer, @timer)

    Thread.new do
      while true
        begin
          @timer.measure do
            sleep @sleep_time
            if rand(100) < @percent_failure
              raise "Failure occurred with sleep_time=#{@sleep_time} and percent failure=#{@percent_failure}"
            end
          end
        rescue Exception => e
          # Error handling...
        end
      end
    end
  end
end

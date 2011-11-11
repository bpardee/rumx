class MyBean
  include Rumx::Bean

  bean_attr_accessor :sleep_time,      :float,   'Amount of time my measured block sleeps'
  bean_attr_accessor :percent_failure, :integer, 'Percentage of time the measured block will fail'
  bean_attr_embed    :timer,                     'Timer for our sleep action'

  def initialize
    @sleep_time      = 0.5
    @percent_failure = 10
    @timer           = Rumx::Beans::Timer.new(:max_errors => 5)

    Thread.new do
      while true
        begin
          @timer.measure do
            if rand(100) < @percent_failure
              raise "Failure occurred with sleep_time=#{@sleep_time} and percent failure=#{@percent_failure}"
            end
            sleep @sleep_time
          end
        rescue Exception => e
          # Error handling...
        end
      end
    end
  end
end

class MyClass

  @@timer_bean = Rumx::TimerBean.new
  Rumx::Bean.root.bean_register_child('timer', @@timer_bean)

  def initialize
    @start_time = Time.now
    Thread.new do
      while true
        seconds = Time.now - @start_time
        begin
          @@timer_bean.measure do
            raise 'foobar' if rand(10) == 0
            sleep seconds/10.0
          end
        rescue Exception => e
        end
      end
    end
  end
end

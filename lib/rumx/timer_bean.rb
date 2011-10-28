require 'benchmark'

module Rumx
  class TimerBean
    include Bean

    bean_attr_reader :total_count, :integer, 'Number of times the measured block has successfully run'
    bean_attr_reader :error_count, :integer, 'Number of times the measured block has raised an exception'
    bean_attr_reader :total_time,  :float,   'Total time in msec for all the successful runs of the timed instruction'
    bean_attr_reader :max_time,    :float,   'The maximum time for all the successful runs of the timed instruction'
    bean_attr_reader :min_time,    :float,   'The minimum time for all the successful runs of the timed instruction'
    bean_attr_reader :last_time,   :float,   'The time for the last successful run of the timed instruction'
    bean_reader      :avg_time,    :float,   'The average time for all successful runs of the timed instruction'
    bean_attr_reader :last_error,  :string,  'The exception message for the last timed instruction that resulted in an exception'
    bean_writer      :reset,       :boolean, 'Reset the times and counts to zero (Note that last_time and last_error are not reset)'

    def initialize
      # Force initialization to avoid race condition (See bean.rb)
      super.bean_mutex
      @last_time     = 0.0
      self.reset = true
    end

    def reset=(val)
      if val
        @total_count = 0
        @error_count = 0
        @min_time    = nil
        @max_time    = 0.0
        @total_time  = 0.0
      end
    end

    def measure
      begin
        current_time = (Benchmark.realtime { yield }) * 1000.0
      rescue Exception => e
        bean_synchronize do
          @error_count += 1
          @last_error = e.message
        end
        raise
      end
      bean_synchronize do
        @last_time    = current_time
        @total_count += 1
        @total_time  += current_time
        @min_time     = current_time if !@min_time || current_time < @min_time
        @max_time     = current_time if current_time > @max_time
      end
      current_time
    end

    def min_time
      @min_time || 0.0
    end

    def avg_time
      # Do the best we can w/o mutexing
      count, time = @total_count, @total_time
      return 0.0 if count == 0
      time / count
    end

    def to_s
      "total_count=#{@total_count} min=#{('%.1f' % min_time)}ms max=#{('%.1f' % max_time)}ms avg=#{('%.1f' % avg_time)}ms"
    end
  end
end

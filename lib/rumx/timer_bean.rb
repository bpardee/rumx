require 'benchmark'

module Rumx
  class TimerBean
    include Bean

    bean_attr_reader :total_count, :integer, 'Number of times the timed instruction has run'
    bean_attr_reader :total_time,  :float,   'Total time in msec for all the runs of the timed instruction'
    bean_attr_reader :max_time,    :float,   'The maximum time for all the runs of the timed instruction'
    bean_attr_reader :min_time,    :float,   'The minimum time for all the runs of the timed instruction'
    bean_attr_reader :last_time,   :float,   'The time for the last run of the timed instruction'
    bean_reader      :avg_time,    :float,   'The average time for all runs of the timed instruction'

    def initialize
      @mutex = Mutex.new
      @total_count = 0
      @last_time   = 0.0
      reset
    end

    def reset
      @mutex.synchronize do
        @total_count = 0
        @min_time    = nil
        @max_time    = 0.0
        @total_time  = 0.0
      end
    end

    def measure
      current_time = (Benchmark.realtime { yield }) * 1000.0
      @mutex.synchronize do
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
      "sample=#{@total_count} min=#{('%.1f' % min_time)}ms max=#{('%.1f' % max_time)}ms avg=#{('%.1f' % avg_time)}ms"
    end
  end
end
module Rumx
  module Beans
    class TimerAndError < Timer

      bean_attr_reader     :error_count,       :integer, 'Number of times the measured block has raised an exception'
      bean_attr_reader     :total_error_count, :integer, 'Total number of times the measured block has raised an exception'
      bean_attr_reader     :errors,            :list,    'List of the last occurring errors', :list_type => :bean
      bean_attr_accessor   :max_errors,        :integer, 'The max number of error descriptions to keep'

      def initialize(opts={})
        super
        @error_count = 0
        @total_error_count = 0
        @errors = []
        @max_errors = (opts[:max_errors] || 1).to_i
      end

      def reset=(val)
        super
        if val
          @error_count = 0
        end
      end

      def max_errors=(max_errors)
        bean_synchronize do
          @max_errors = max_errors
          @errors.shift while @errors.size > @max_errors
        end
      end

      def measure
        super
      rescue Exception => e
        bean_synchronize do
          @error_count += 1
          @total_error_count += 1
          @errors << Message.new(e.message)
          @errors.shift while @errors.size > @max_errors
        end
        raise
      end

      def to_s
        "error_count=#{@error_count}" + super
      end
    end
  end
end

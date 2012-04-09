module Rumx
  module Beans
    class Error
      include Bean

      bean_attr_reader     :error_count, :integer, 'Number of times the measured block has raised an exception'
      bean_attr_reader     :errors,      :list,    'List of the last occurring errors', :list_type => :bean
      bean_attr_accessor   :max_errors,  :integer, 'The max number of error descriptions to keep'
      bean_attr_writer     :reset,       :boolean, 'Reset the error count'

      def initialize(opts={})
        @errors = []
        @max_errors = (opts[:max_errors] || 1).to_i
      end

      def reset=(val)
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

      def perform(prefix='')
        yield
      rescue Exception => e
        add_exception(e)
        raise
      end

      def add_exception(exception)
        bean_synchronize do
          @error_count += 1
          @errors << Message.new(exception.message)
          @errors.shift while @errors.size > @max_errors
        end
      end

      def to_s
        "error_count=#{@error_count} last_error=#{@errors.last}"
      end
    end
  end
end

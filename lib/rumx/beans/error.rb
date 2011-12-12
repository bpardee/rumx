module Rumx
  module Beans
    class Error
      include Bean

      bean_attr_reader     :error_count, :integer, 'Number of times the measured block has raised an exception'
      bean_attr_embed_list :errors,                'List of the last occurring errors'

      def initialize(opts={})
        @errors = []
        @max_errors = (opts[:max_errors] || 1).to_i
      end

      def reset=(val)
        if val
          @error_count = 0
        end
      end

      def perform(prefix='')
        yield
      rescue Exception => e
        bean_synchronize do
          @error_count += 1
          @errors << Message.new(e.message)
          @errors.shift while @errors.size > @max_errors
        end
        raise
      end

      def to_s
        "error_count=#{@error_count} last_error=#{@errors.last}"
      end
    end
  end
end

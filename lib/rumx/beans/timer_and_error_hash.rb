module Rumx
  module Beans
    # Extend Beans::Hash specifically for Beans::TimerAndError
    class TimerAndErrorHash < Hash
      def initialize
        super { TimerAndError.new }
      end
    end
  end
end

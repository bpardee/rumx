module Rumx
  module Beans
    # Extend Beans::Hash specifically for Beans::Timer
    class TimerHash < Hash
      def initialize
        super { Timer.new }
      end
    end
  end
end

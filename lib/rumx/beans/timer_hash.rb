module Rumx
  module Beans
    class TimerHash < Hash
      def initialize
        super { Timer.new }
      end
    end
  end
end

module Rumx
  module Beans
    class Message
      include ::Rumx::Bean

      bean_attr_reader :message, :string,  'Message'
      # TODO: create time and date types
      bean_attr_reader :time,    :string,  'Time that the message occurred'

      def initialize(message, time=nil)
        @message = message
        @time = (time || Time.now).to_s
      end
    end
  end
end

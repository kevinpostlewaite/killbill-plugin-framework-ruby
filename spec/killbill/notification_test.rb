require 'killbill/notification'

module Killbill
  module Plugin
    class NotificationTest < Notification

      attr_reader :counter

      def initialize(*args)
        @counter = 0
      end

      def on_event(event)
        @counter += 1
      end

    end
  end
end

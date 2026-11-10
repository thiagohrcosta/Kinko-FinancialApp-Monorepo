module ApplicationCable
  # Deposit confirmations and other per-user events (see Payments::DepositService).
  class NotificationsChannel < ApplicationCable::Channel
    def subscribed
      stream_from "notifications:user:#{current_user.id}"
    end
  end
end

module ApplicationCable
  class NotificationsChannel < ApplicationCable::Channel
    def subscribed
      token = params[:token]

      unless token.present?
        reject_subscription
        return
      end

      begin
        decoded = JsonWebToken.decode(token)
        user_id = decoded[:user_id]

        user = User.find(user_id)
        stream_from "notifications:user:#{user_id}"

        Rails.logger.info("✓ NotificationsChannel subscribed: user_id=#{user_id}")
      rescue => e
        Rails.logger.error("NotificationsChannel subscription failed: #{e.message}")
        reject_subscription
      end
    end

    def unsubscribed
      Rails.logger.info("✓ NotificationsChannel unsubscribed")
    end
  end
end

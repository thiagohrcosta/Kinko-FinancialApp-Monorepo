module ApplicationCable
  # Authenticates the WebSocket once, with the same JWT as the API:
  #   /cable?token=<jwt>
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private
      def find_verified_user
        payload = JsonWebToken.decode(request.params[:token].to_s)
        User.find_by(id: payload[:user_id]) || reject_unauthorized_connection
      rescue JWT::DecodeError
        reject_unauthorized_connection
      end
  end
end

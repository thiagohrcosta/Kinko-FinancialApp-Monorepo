# Authenticates merchant (business) requests.
#
#   Authorization: Bearer kinko_sk_...   → server-to-server integrations
#   Authorization: Bearer <JWT>          → the merchant's own dashboard
#
# Controllers that manage credentials (API keys, webhook secrets) call
# `merchant_session_only!` so a leaked API key cannot mint new keys.
module MerchantAuthenticatable
  extend ActiveSupport::Concern
  include Authenticatable

  included do
    skip_before_action :authenticate_user!
    before_action :authenticate_merchant!
  end

  class_methods do
    def merchant_session_only!
      before_action :require_session!
    end
  end

  private

  attr_reader :current_api_key

  def authenticate_merchant!
    token = request.headers["Authorization"].to_s[/\ABearer\s+(\S+)\z/i, 1]

    if token&.start_with?(MerchantApiKey::PREFIX)
      @current_api_key = MerchantApiKey.authenticate(token)
      return render json: { error: "Invalid API key" }, status: :unauthorized unless @current_api_key

      @current_api_key.touch_last_used!
      @current_user = @current_api_key.user
    else
      authenticate_user!
      return if performed?
    end

    render json: { error: "Business account required" }, status: :forbidden unless current_user.business?
  end

  def require_session!
    render json: { error: "This endpoint requires a dashboard session, not an API key" }, status: :forbidden if current_api_key
  end

  def current_merchant
    current_user
  end
end

# app/concerns/authenticatable.rb
module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  private

  def authenticate_user!
    header = request.headers['Authorization'].to_s
    token = header.split(' ').last
    token = nil if header.match?(/\ABearer\s*\z/i)
    raise ExceptionHandler::MissingToken, 'Missing Token' if token.blank?

    @decoded = JsonWebToken.decode(token)
    @current_user = User.find(@decoded[:user_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :unauthorized
  end

  def current_user
    @current_user
  end
end
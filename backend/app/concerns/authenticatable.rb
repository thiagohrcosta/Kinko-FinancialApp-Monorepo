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
    raise ExceptionHandler::MissingToken, 'Unauthorized' if token.blank?

    puts "DEBUG TOKEN: header = #{header.inspect}"
    puts "DEBUG TOKEN: token = #{token.inspect}"

    @decoded = JsonWebToken.decode(token)
    puts "DEBUG TOKEN: decoded = #{@decoded.inspect}"

    @current_user = User.find(@decoded[:user_id])
    puts "DEBUG TOKEN: found user = #{@current_user.inspect}"
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :unauthorized
  end

  def current_user
    @current_user
  end
end
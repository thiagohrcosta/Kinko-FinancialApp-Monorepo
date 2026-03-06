module Api
  module V1
    class AuthController < ApplicationController

      # POST /api/v1/auth/register
      def register
        user = User.new(user_params)
        if user.save
          token = JsonWebToken.encode(user_id: user.id)
          render json: { token: token, user: user }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/auth/login
      def login
        puts "DEBUG AUTH: email = #{params[:email]}"
        user = User.find_by(email: params[:email])
        puts "DEBUG AUTH: found user = #{user.inspect}"

        if user&.valid_password?(params[:password])
          puts "DEBUG AUTH: password valid for user #{user.id}"
          token = JsonWebToken.encode(user_id: user.id)
          puts "DEBUG AUTH: generated token with user_id = #{user.id}"
          render json: { token: token, user: user }, status: :ok
        else
          puts "DEBUG AUTH: password invalid or user not found"
          render json: { error: 'Email ou senha inválidos' }, status: :unauthorized
        end
      end

      private

      def user_params
        params.permit(
          :email,
          :full_name,
          :user_type,
          :business_name,
          :business_sector,
          :document_number,
          :phone_number,
          :address_street,
          :address_number,
          :address_city,
          :address_complement,
          :address_state,
          :address_neighborhood,
          :address_zip_code,
          :password,
          :password_confirmation
        )
      end
    end
  end
end
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
        user = User.find_by(email: params[:email])
        if user&.valid_password?(params[:password])
          token = JsonWebToken.encode(user_id: user.id)
          render json: { token: token, user: user }, status: :ok
        else
          render json: { error: 'Email ou senha inválidos' }, status: :unauthorized
        end
      end

      private

      def user_params
        params.permit(
          :email,
          :full_name,
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
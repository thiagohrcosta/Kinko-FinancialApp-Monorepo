module Api
  module V1
    # The signed-in user's own profile. For now only the country and state can
    # change (users created before the country was asked must add it, #83);
    # the rest of the profile comes with corrections (#90).
    class ProfilesController < ApplicationController
      include Authenticatable

      # GET /api/v1/profile
      def show
        render json: profile_json
      end

      # PATCH /api/v1/profile  { address_country, address_state }
      def update
        if current_user.update(params.permit(:address_country, :address_state))
          render json: profile_json
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private
        def profile_json
          current_user.as_json(only: %i[id email full_name user_type address_city address_state address_country])
                      .merge(privacy_region: current_user.privacy_region)
        end
    end
  end
end

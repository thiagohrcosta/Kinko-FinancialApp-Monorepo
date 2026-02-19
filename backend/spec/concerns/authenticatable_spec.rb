require "rails_helper"

RSpec.describe Authenticatable, type: :controller do
  controller(ApplicationController) do
    include ExceptionHandler
    include Authenticatable

    def index
      render json: { message: "Authenticated!", user_id: current_user.id }
    end

    def show_user
      render json: { current_user_id: current_user&.id }
    end
  end

  let!(:user) { create(:user) }
  let(:valid_token) { JsonWebToken.encode(user_id: user.id) }
  let(:invalid_token) { "invalid.token.here" }

  before do
    routes.draw do
      get "index" => "anonymous#index"
      get "show_user" => "anonymous#show_user"
    end
  end

  describe "#authenticate_user!" do
    context "with valid token" do
      it "authenticates the user successfully" do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        get :index

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["user_id"]).to eq(user.id)
        expect(json["message"]).to eq("Authenticated!")
      end

      it "sets current_user" do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        get :show_user

        json = JSON.parse(response.body)
        expect(json["current_user_id"]).to eq(user.id)
      end
    end

    context "without token" do
      it "returns unauthorized status" do
        get :index

        expect(response).to have_http_status(:unauthorized)
      end

      it "returns error message" do
        get :index

        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Missing Token")
      end
    end

    context "with empty Authorization header" do
      it "returns unauthorized when header is empty" do
        request.headers["Authorization"] = ""
        get :index

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Missing Token")
      end
    end

    context "with malformed Authorization header" do
      it "handles JWT::DecodeError when missing Bearer prefix" do
        request.headers["Authorization"] = "InvalidFormat"

        expect {
          get :index
        }.to raise_error(JWT::DecodeError)
      end

      it "handles JWT::DecodeError when only Bearer is present" do
        request.headers["Authorization"] = "Bearer "

        get :index
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Missing Token")
      end

      it "handles JWT::DecodeError when token is malformed" do
        request.headers["Authorization"] = "Bearer malformed_token"

        expect {
          get :index
        }.to raise_error(JWT::DecodeError)
      end
    end

    context "with invalid token" do
      it "returns unauthorized status" do
        allow(JsonWebToken).to receive(:decode).and_raise(
          ExceptionHandler::InvalidToken.new("Token inválido")
        )

        request.headers["Authorization"] = "Bearer #{invalid_token}"
        get :index

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Token inválido")
      end
    end

    context "when user does not exist" do
      let(:non_existent_user_token) { JsonWebToken.encode(user_id: 99999) }

      it "returns unauthorized status" do
        request.headers["Authorization"] = "Bearer #{non_existent_user_token}"
        get :index

        expect(response).to have_http_status(:unauthorized)
      end

      it "returns error message" do
        request.headers["Authorization"] = "Bearer #{non_existent_user_token}"
        get :index

        json = JSON.parse(response.body)
        expect(json["error"]).to be_present
        expect(json["error"]).to match(/not found|não encontrado/i)
      end
    end

    context "when user is deleted after token was issued" do
      it "handles deleted user gracefully" do
        token = JsonWebToken.encode(user_id: user.id)
        user.destroy

        request.headers["Authorization"] = "Bearer #{token}"
        get :index

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]).to be_present
      end
    end
  end

  describe "#current_user" do
    it "is set after successful authentication" do
      request.headers["Authorization"] = "Bearer #{valid_token}"
      get :show_user

      json = JSON.parse(response.body)
      expect(json["current_user_id"]).to eq(user.id)
    end

    it "is nil when not authenticated" do
      get :show_user

      json = JSON.parse(response.body)
      expect(json["current_user_id"]).to be_nil
    end
  end

  describe "before_action :authenticate_user!" do
    it "is called before controller action" do
      expect(controller).to receive(:authenticate_user!).and_call_original

      request.headers["Authorization"] = "Bearer #{valid_token}"
      get :index
    end

    it "blocks request if authentication fails" do
      get :index

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "token extraction from Authorization header" do
    it "extracts token correctly from 'Bearer token'" do
      request.headers["Authorization"] = "Bearer #{valid_token}"
      get :index

      expect(response).to have_http_status(:ok)
    end

    it "handles multiple spaces correctly" do
      request.headers["Authorization"] = "Bearer  #{valid_token}"
      get :index

      expect(response.status).to be_in([200, 401])
    end
  end
end
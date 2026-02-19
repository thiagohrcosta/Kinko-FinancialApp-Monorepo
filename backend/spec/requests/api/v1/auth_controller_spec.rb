require "rails_helper"

RSpec.describe Api::V1::AuthController, type: :request do
  let(:valid_attributes) do
    {
      email: "user@example.com",
      full_name: "John Doe",
      document_number: "12345678901",
      phone_number: "11999999999",
      address_street: "Main Street",
      address_number: "123",
      address_city: "São Paulo",
      address_state: "SP",
      address_neighborhood: "Centro",
      address_zip_code: "01234567",
      password: "password123",
      password_confirmation: "password123"
    }
  end

  let(:invalid_attributes) do
    {
      email: "",
      password: ""
    }
  end

  describe "POST /api/v1/auth/register" do
    context "with valid parameters" do
      it "creates a new user" do
        expect {
          post "/api/v1/auth/register", params: valid_attributes
        }.to change(User, :count).by(1)
      end

      it "returns a token" do
        post "/api/v1/auth/register", params: valid_attributes

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["token"]).to be_present
      end

      it "returns user data" do
        post "/api/v1/auth/register", params: valid_attributes

        json = JSON.parse(response.body)
        expect(json["user"]["email"]).to eq("user@example.com")
        expect(json["user"]["full_name"]).to eq("John Doe")
      end

      it "generates a valid JWT token" do
        post "/api/v1/auth/register", params: valid_attributes

        json = JSON.parse(response.body)
        token = json["token"]

        decoded = JsonWebToken.decode(token)
        expect(decoded["user_id"]).to eq(User.last.id)
      end
    end

    context "with invalid parameters" do
      it "does not create a new user" do
        expect {
          post "/api/v1/auth/register", params: invalid_attributes
        }.not_to change(User, :count)
      end

      it "returns unprocessable entity status" do
        post "/api/v1/auth/register", params: invalid_attributes

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns error messages" do
        post "/api/v1/auth/register", params: invalid_attributes

        json = JSON.parse(response.body)
        expect(json["errors"]).to be_present
        expect(json["errors"]).to be_an(Array)
      end
    end

    context "with mismatched password confirmation" do
      it "returns validation error" do
        params = valid_attributes.merge(password_confirmation: "wrong")
        post "/api/v1/auth/register", params: params

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to include(match(/password confirmation/i))
      end
    end

    context "with duplicate email" do
      before { create(:user, email: "user@example.com") }

      it "returns validation error" do
        post "/api/v1/auth/register", params: valid_attributes

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to include(match(/email/i))
      end
    end
  end

  describe "POST /api/v1/auth/login" do
    let!(:user) { create(:user, email: "user@example.com", password: "password123") }

    context "with valid credentials" do
      it "returns a token" do
        post "/api/v1/auth/login", params: {
          email: "user@example.com",
          password: "password123"
        }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["token"]).to be_present
      end

      it "returns user data" do
        post "/api/v1/auth/login", params: {
          email: "user@example.com",
          password: "password123"
        }

        json = JSON.parse(response.body)
        expect(json["user"]["id"]).to eq(user.id)
        expect(json["user"]["email"]).to eq("user@example.com")
      end

      it "generates a valid JWT token" do
        post "/api/v1/auth/login", params: {
          email: "user@example.com",
          password: "password123"
        }

        json = JSON.parse(response.body)
        token = json["token"]

        decoded = JsonWebToken.decode(token)
        expect(decoded["user_id"]).to eq(user.id)
      end
    end

    context "with invalid email" do
      it "returns unauthorized status" do
        post "/api/v1/auth/login", params: {
          email: "wrong@example.com",
          password: "password123"
        }

        expect(response).to have_http_status(:unauthorized)
      end

      it "returns error message" do
        post "/api/v1/auth/login", params: {
          email: "wrong@example.com",
          password: "password123"
        }

        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Email ou senha inválidos")
      end
    end

    context "with invalid password" do
      it "returns unauthorized status" do
        post "/api/v1/auth/login", params: {
          email: "user@example.com",
          password: "wrongpassword"
        }

        expect(response).to have_http_status(:unauthorized)
      end

      it "returns error message" do
        post "/api/v1/auth/login", params: {
          email: "user@example.com",
          password: "wrongpassword"
        }

        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Email ou senha inválidos")
      end
    end

    context "with missing parameters" do
      it "handles missing email" do
        post "/api/v1/auth/login", params: { password: "password123" }

        expect(response).to have_http_status(:unauthorized)
      end

      it "handles missing password" do
        post "/api/v1/auth/login", params: { email: "user@example.com" }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
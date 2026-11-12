Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  # namespace :api do
  namespace :api do
    namespace :v1 do
      post "auth/register", to: "auth#register"
      post "auth/login",    to: "auth#login"

      resources :accounts, only: [ :index, :show, :create ] do
        collection do
          get :balance
          get :transactions
          get :insights
        end

        member do
          get :balance
        end
      end

      resource :profile, only: [ :show, :update ]

      resources :deposits, only: [ :create ]
      resources :transfers, only: [ :create ]

      # Payer side: preview and pay a copy-and-paste payment code.
      resources :payment_requests, only: [ :show ], param: :code do
        member do
          post :pay
          get :qr
        end
      end

      # Merchant side: Kinko API key (integrations) or business JWT (dashboard).
      namespace :merchant do
        resources :payment_requests, only: [ :index, :show, :create ] do
          member { post :cancel }
        end
        resources :api_keys, only: [ :index, :create, :destroy ]
        resource :webhook_endpoint, only: [ :show, :update, :destroy ] do
          post :rotate_secret
        end
      end

      namespace :webhooks do
        post "stripe", to: "stripe#create"
      end
    end
  end
end

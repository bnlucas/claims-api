Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  namespace :api do
    namespace :v1 do
      scope :audit_logs, controller: :audit_logs do
        get "/",          to: "audit_logs#index", as: :api_v1_audit_logs
        get "/claim/:id", to: "audit_logs#claim", as: :api_v1_claim_audit_logs
      end
      scope :customers, controller: :customers do
        get "/",          to: "customers#index", as: :api_v1_customers
        get "/:id",       to: "customers#show",  as: :api_v1_customer
      end

      scope :claims, controller: :claims do
        get    "/",       to: "claims#index",    as: :api_v1_claims
        post   "/",       to: "claims#create",   as: :api_v1_claims_create
        get    "/:id",    to: "claims#show",     as: :api_v1_claim
        put    "/:id",    to: "claims#update",   as: :api_v1_claim_update
        delete "/:id",    to: "claims#delete",   as: :api_v1_claim_delete
      end
    end
  end
end

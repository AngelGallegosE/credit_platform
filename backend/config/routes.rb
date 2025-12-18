
# Autenticación para Sidekiq Web UI
# Sidekiq::Web.use Rack::Auth::Basic do |username, password|
#   ActiveSupport::SecurityUtils.secure_compare(
#     ::Digest::SHA256.hexdigest(username),
#     ::Digest::SHA256.hexdigest(ENV.fetch("SIDEKIQ_USERNAME", "admin"))
#   ) &
#     ActiveSupport::SecurityUtils.secure_compare(
#       ::Digest::SHA256.hexdigest(password),
#       ::Digest::SHA256.hexdigest(ENV.fetch("SIDEKIQ_PASSWORD", "password"))
#     )
# end

require "sidekiq/web"

Rails.application.routes.draw do
  # Sidekiq Web UI
  mount Sidekiq::Web, at: "/sidekiq"

  devise_for :users,
    defaults: { format: :json },
    controllers: {
      registrations: "users/registrations",
      sessions: "users/sessions"
    }

  devise_scope :user do
    post "/signup", to: "users/registrations#create"
    post "/login",  to: "users/sessions#create"
    delete "/logout", to: "users/sessions#destroy"
  end

  namespace :api do
    namespace :v1 do
      namespace :analytics do
        namespace :credit_applications do
          get :by_status
        end
      end

      resources :credit_applications, only: [ :create, :index, :show, :update, :destroy ]

      namespace :webhooks do
        post "banking_data", to: "banking_data#create"
      end
    end
  end
end

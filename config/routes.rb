Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :contracts, only: [ :index ]
      resources :savings, only: [ :show ], param: :ocid, constraints: { ocid: /[^\/]+/ }
    end
  end
end

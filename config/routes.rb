Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :contracts, only: [ :index ]
      resources :savings, only: [ :show ], param: :ocid, constraints: { ocid: /[^\/]+/ }
      get "savings/:ocid/peer-comparison", to: "savings#peer_comparison",
          as: :peer_comparison,
          constraints: { ocid: /[^\/]+/ }
      delete "savings/:type/:savings_id", to: "savings#destroy",
             as: :delete_saving,
             constraints: { type: /cashable|non-cashable|non-monetisable/, savings_id: /\d+/ }
    end
  end
end

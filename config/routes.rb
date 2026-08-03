Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :contracts, only: [ :index ]
      resources :savings, only: [ :show, :update ], param: :ocid, constraints: { ocid: /[^\/]+/ }
      get "savings/:ocid/peer-comparison", to: "savings#peer_comparison",
          as: :peer_comparison,
          constraints: { ocid: /[^\/]+/ }
      delete "savings/:type/:savings_id", to: "savings#destroy",
             as: :delete_saving,
             constraints: { savings_id: /\d+/ }
      post "savings/:ocid/:type", to: "savings#create",
           as: :create_saving,
           constraints: { ocid: /[^\/]+/ }
    end
  end
end

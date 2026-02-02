Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Projects
      resources :projects, param: :key, only: [:index, :create, :show, :update, :destroy] do
        resources :issues, only: [:index, :create]
        get :board, to: "boards#by_project"
      end

      # Issues (direct access by tracking_id)
      resources :issues, param: :tracking_id, only: [:show, :update, :destroy] do
        member do
          post :transitions, to: "transitions#create"
          post :comments, to: "comments#create"
        end
      end

      # Boards
      resources :boards, only: [:show, :update]

      # Repair
      post :repair, to: "repair#create"

      # Current user
      get :me, to: "me#show"
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end

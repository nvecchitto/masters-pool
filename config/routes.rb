Rails.application.routes.draw do
  # Auth
  get    "login",    to: "sessions#new",       as: :login
  post   "login",    to: "sessions#create"
  delete "logout",   to: "sessions#destroy",   as: :logout
  get    "sign_up",  to: "registrations#new",  as: :sign_up
  post   "sign_up",  to: "registrations#create"

  resources :pools, only: %i[index create destroy] do
    member do
      post :join
      post :start_draft
    end

    # GET  /pools/:pool_id/dashboard  → DashboardController#index
    get  "dashboard", to: "dashboard#index", as: :dashboard

    # GET  /pools/:pool_id/teams/:team_id/scorecard → DashboardController#team_scorecard
    get  "teams/:team_id/scorecard", to: "dashboard#team_scorecard", as: :team_scorecard

    # GET  /pools/:pool_id/draft       → DraftController#show
    # POST /pools/:pool_id/draft/pick  → DraftController#pick
    get  "draft",      to: "draft#show", as: :draft
    post "draft/pick", to: "draft#pick", as: :draft_pick
    post "draft/sync", to: "draft#sync", as: :draft_sync
  end

  root "pages#home"
end

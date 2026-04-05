Rails.application.routes.draw do
  resources :pools, only: %i[index create] do
    # GET  /pools/:pool_id/dashboard  → DashboardController#index
    get  "dashboard", to: "dashboard#index", as: :dashboard

    # GET  /pools/:pool_id/draft       → DraftController#show
    # POST /pools/:pool_id/draft/pick  → DraftController#pick
    get  "draft",      to: "draft#show", as: :draft
    post "draft/pick", to: "draft#pick", as: :draft_pick
    post "draft/sync", to: "draft#sync", as: :draft_sync
  end

  root "pages#home"
end

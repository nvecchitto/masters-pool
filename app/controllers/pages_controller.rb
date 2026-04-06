class PagesController < ApplicationController
  def home
    all_pools = Pool.includes(:tournament, :participants, :teams).order(created_at: :desc)

    if logged_in?
      @my_pools   = all_pools.select { |p| p.member?(current_user) }
      @open_pools = all_pools.select { |p| p.joinable? && !p.member?(current_user) }
    else
      @my_pools   = []
      @open_pools = all_pools.select(&:joinable?)
    end

    @api_tournaments = SportsDataService.new.fetch_tournaments
  rescue KeyError, SportsDataService::ApiError => e
    @api_tournaments = []
    @api_error       = e.message
  end
end

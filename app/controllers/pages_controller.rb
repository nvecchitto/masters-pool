class PagesController < ApplicationController
  def home
    @pools           = Pool.includes(:tournament).all
    @api_tournaments = SportsDataService.new.fetch_tournaments
  rescue KeyError, SportsDataService::ApiError => e
    @api_tournaments = []
    @api_error       = e.message
  end
end

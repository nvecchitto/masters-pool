class TournamentsController < ApplicationController
  def create
    @tournament = Tournament.find_or_initialize_by(
      sportsdata_id: params[:sportsdata_id]
    )
    @tournament.assign_attributes(
      name:         params[:tournament_name],
      status:       "upcoming",
      total_rounds: params[:total_rounds].presence&.to_i || 4
    )

    if @tournament.save
      redirect_to root_path, notice: "\"#{@tournament.name}\" added."
    else
      redirect_to root_path, alert: @tournament.errors.full_messages.to_sentence
    end
  end
end

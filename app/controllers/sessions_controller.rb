class SessionsController < ApplicationController
  def new
    redirect_to root_path if logged_in?
  end

  def create
    participant = Participant.find_by(email: params[:email].to_s.strip.downcase)

    if participant&.registered? && participant.authenticate(params[:password])
      session[:participant_id] = participant.id
      redirect_to (session.delete(:return_to) || root_path), notice: "Welcome back, #{participant.name}!"
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:participant_id)
    redirect_to login_path, notice: "You've been logged out."
  end
end

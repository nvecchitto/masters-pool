class RegistrationsController < ApplicationController
  def new
    redirect_to root_path if logged_in?
  end

  def create
    email = params[:email].to_s.strip.downcase
    name  = params[:name].to_s.strip

    # Claim an existing placeholder or create a new participant
    participant = Participant.find_or_initialize_by(email: email)
    participant.name = name if name.present?
    participant.password = params[:password]
    participant.password_confirmation = params[:password_confirmation]

    if params[:password].to_s.length < 6
      flash.now[:alert] = "Password must be at least 6 characters."
      render :new, status: :unprocessable_entity
      return
    end

    if params[:password] != params[:password_confirmation]
      flash.now[:alert] = "Passwords do not match."
      render :new, status: :unprocessable_entity
      return
    end

    if participant.save
      session[:participant_id] = participant.id
      redirect_to root_path, notice: "Account created! Welcome, #{participant.name}."
    else
      flash.now[:alert] = participant.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end
end

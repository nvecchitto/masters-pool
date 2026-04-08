class ApplicationController < ActionController::Base
  helper_method :current_user, :logged_in?

  before_action :touch_last_active_at

  private

  def current_user
    @current_user ||= Participant.find_by(id: session[:participant_id]) if session[:participant_id]
  end

  def touch_last_active_at
    current_user&.update_columns(last_active_at: Time.current)
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    unless logged_in?
      session[:return_to] = request.fullpath
      redirect_to login_path, alert: "Please log in to continue."
    end
  end
end

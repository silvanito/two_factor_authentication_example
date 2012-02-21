class ApplicationController < ActionController::Base
  protect_from_forgery
  helper :all
  helper_method :current_user_session, :current_user
  before_filter :require_user # must be logged in, redirect to login if not
  before_filter :require_two_factor # verify two factor token

  private

  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.record
  end

  def require_user
    unless current_user
      store_location
      flash[:notice] = "You must be logged in to access this page"
      redirect_to login_url
      return false
    end
  end

  def require_no_user
    if current_user
      store_location
      flash[:notice] = "You must be logged out to access this page"
      redirect_to '/'
      return false
    end
  end

  def require_two_factor
    return false unless current_user && two_factor_required?
    redirect_to confirm_url, :notice => "Session needs confirmation token" unless two_factor_confirmed?
  end

  def two_factor_required?
    # TODO: check request_ip matches LAN
    true
  end

  # NOTE:
  # 'two_factor_confirmed?' doesn't persist with "remember_me", it dies
  # with the session.
  #
  # NOTE:
  # If the Authlogic session expires/goes stale, the entire session will
  # be reset on the next redirect to a new user session.
  #
  # @return [Boolean] true if two factor confirmed
  def two_factor_confirmed?
    !session[:two_factor_confirmed].nil?
  end

  def require_no_user
    if current_user
      store_location
      flash[:notice] = "You must be logged out to access this page"
      redirect_to '/'
      return false
    end
  end

  def store_location
    session[:return_to] = request.fullpath
  end

  def redirect_back(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

end

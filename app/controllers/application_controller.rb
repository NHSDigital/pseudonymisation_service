# Main controller. Primarily handles abstract site-wide authentication logic.
class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  before_action :authenticate
  before_action :log_user

  # Any failure to persist is the fault of the server, rather than the client;
  # from the client's point of view, the server is stateless.
  rescue_from ActiveRecord::RecordInvalid do
    render status: :internal_server_error
  end

  def info
    render json: { api_version: '1' }
  end

  # Return a basic classname and object reference instead of the full internal controller state
  # This reduces the #inspect output from about 800KB to about 50 characters
  #
  # We wouldn't ordinarily want to call #inspect on a controller, but in Ruby 3.x,
  # NoMethodError calls #inspect on the embedded object, and includes it all,
  # resulting in excessively large error messages.
  def inspect
    to_s
  end

  private

  def authenticate
    authenticate_or_request_with_http_token do |token, _options|
      @current_user = User.retrieve_by(token: token)
    end
  end

  def current_user
    @current_user ||= authenticate
  end

  def log_user
    if current_user
      Rails.logger.info("processing request for user: #{current_user.try(:username)}")
    else
      Rails.logger.info('processing request for unauthenticated user')
    end
  end
end

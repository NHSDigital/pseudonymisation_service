# Main controller. Primarily handles abstract site-wide authentication logic.
class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  before_action :authenticate

  # Any failure to persist is the fault of the server, rather than the client;
  # from the client's point of view, the server is stateless.
  rescue_from ActiveRecord::RecordInvalid do
    render status: :internal_server_error
  end

  def info
    render json: { api_version: '1' }
  end

  private

  def authenticate
    authenticate_or_request_with_http_token do |token, _options|
      @current_user = User.retrieve_by(token: token)

      if current_user
        Rails.logger.info("processing request for user: #{current_user.try(:username)}")
      else
        Rails.logger.info('processing request for unauthenticated user')
      end
    end
  end

  def current_user
    @current_user ||= authenticate
  end
end

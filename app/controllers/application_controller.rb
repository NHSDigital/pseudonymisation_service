class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  before_action :authenticate

  def info
    render json: { api_version: '1' }
  end

  private

  def authenticate
    authenticate_or_request_with_http_token do |token, _options|
      Userlist.find_by(token: token)
    end
  end
end

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'mocha/minitest'

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Prevent this bleeding across tests:
  setup { Userlist.token_cache(clear: true) }
end

class ActionDispatch::IntegrationTest
  setup :authenticate_user

  private

  attr_reader :current_user

  def authenticate_user(user: users(:test_user))
    ActionController::HttpAuthentication::Token.stubs(authenticate: user)
    @current_user = user
  end

  def sign_out
    ActionController::HttpAuthentication::Token.unstub(:authenticate)
    @current_user = nil
  end

  def auth_headers(token: nil)
    token ||= 'test_user:2e5e5ea81c9e342d8f03b0233770d1006255c418b8156f0a907e69b73e56bcb4'
    header = ActionController::HttpAuthentication::Token.encode_credentials(token)
    { Authorization: header }
  end
end

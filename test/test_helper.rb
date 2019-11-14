ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

class ActionDispatch::IntegrationTest
  private

  def auth_headers(token: nil)
    token ||= '2e5e5ea81c9e342d8f03b0233770d1006255c418b8156f0a907e69b73e56bcb4'
    header = ActionController::HttpAuthentication::Token.encode_credentials(token)
    { Authorization: header }
  end
end

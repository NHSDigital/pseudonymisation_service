require 'test_helper'

class UserlistTest < ActiveSupport::TestCase
  test 'can find entries by valid token' do
    token = '2e5e5ea81c9e342d8f03b0233770d1006255c418b8156f0a907e69b73e56bcb4'
    assert_equal 'test_user', Userlist.find_by(token: token)
  end

  test 'returns nothing for invalid token' do
    assert_nil Userlist.find_by(token: 'wibble')
  end
end

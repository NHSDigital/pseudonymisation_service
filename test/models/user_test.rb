require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'should return user by token if found' do
    token = '2e5e5ea81c9e342d8f03b0233770d1006255c418b8156f0a907e69b73e56bcb4'
    assert_equal users(:test_user), User.retrieve_by(token: token)

    users(:test_user).destroy
    assert_nil User.retrieve_by(token: token)
  end

  test 'should not return result for junk token' do
    assert_nil User.retrieve_by(token: 'rubbish')
  end
end

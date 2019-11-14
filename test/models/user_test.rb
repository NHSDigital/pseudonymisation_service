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

  test 'should know which keys use have been granted of' do
    assert_equal [pseudonymisation_keys(:primary_one)], users(:test_user).pseudonymisation_keys
  end

  test 'should expose their ability' do
    ability = users(:test_user).ability
    assert ability.can? :read, pseudonymisation_keys(:primary_one)
    assert ability.cannot? :read, pseudonymisation_keys(:primary_two)
  end
end

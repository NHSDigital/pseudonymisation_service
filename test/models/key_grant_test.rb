require 'test_helper'

class KeyGrantTest < ActiveSupport::TestCase
  test 'should uniquely associate user and pseudonymisation key' do
    old_grant = key_grants(:grant_one)
    new_grant = KeyGrant.new(user: old_grant.user, pseudonymisation_key: old_grant.pseudonymisation_key)

    refute new_grant.valid?
    assert_includes new_grant.errors.details[:user], error: :taken, value: new_grant.user

    new_key = pseudonymisation_keys(:compound_one)
    new_grant.pseudonymisation_key = new_key
    assert new_grant.save

    assert_includes new_grant.user.pseudonymisation_keys, new_key
  end

  test 'should only grant to primary pseudonymisation keys' do
    grant = KeyGrant.new(user: users(:test_user))

    grant.pseudonymisation_key = pseudonymisation_keys(:primary_two)
    grant.valid?
    refute_includes grant.errors.details[:pseudonymisation_key], error: 'not a primary pseudo key'

    grant.pseudonymisation_key = pseudonymisation_keys(:repseudo_one)
    grant.valid?
    assert_includes grant.errors.details[:pseudonymisation_key], error: 'not a primary pseudo key'

    grant.pseudonymisation_key = pseudonymisation_keys(:compound_one)
    grant.valid?
    refute_includes grant.errors.details[:pseudonymisation_key], error: 'not a primary pseudo key'
  end
end

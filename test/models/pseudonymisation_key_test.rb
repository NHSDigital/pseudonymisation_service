require 'test_helper'

class PseudonymisationKeyTest < ActiveSupport::TestCase
  setup do
    @primary1 = pseudonymisation_keys(:primary_one)
    @primary2 = pseudonymisation_keys(:primary_two)
    @secondary1 = pseudonymisation_keys(:repseudo_one)
  end

  test 'should scope primary keys' do
    assert PseudonymisationKey.primary.exists?(@primary1.id)
    refute PseudonymisationKey.primary.exists?(@secondary1.id)
  end

  test 'should scope secondary keys' do
    refute PseudonymisationKey.secondary.exists?(@primary1.id)
    assert PseudonymisationKey.secondary.exists?(@secondary1.id)
  end

  test 'a key should list its secondary keys' do
    assert_includes @primary1.secondary_keys, @secondary1
  end

  test 'a key should know its parent key' do
    assert_equal @primary1, @secondary1.parent_key
    assert_nil @primary1.parent_key
  end

  test 'should return chain' do
    assert_equal [@primary1], @primary1.chain
    assert_equal [@primary1, @secondary1], @secondary1.chain
  end
end

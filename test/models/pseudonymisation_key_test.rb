require 'test_helper'

class PseudonymisationKeyTest < ActiveSupport::TestCase
  setup do
    @primary1 = pseudonymisation_keys(:primary_one)
    @primary2 = pseudonymisation_keys(:primary_two)
    @secondary1 = pseudonymisation_keys(:repseudo_one)
    @secondary2 = pseudonymisation_keys(:repseudo_two)
    @secondary3 = pseudonymisation_keys(:repseudo_three)
    @compound1 = pseudonymisation_keys(:compound_one)
  end

  test 'the primary scope' do
    assert PseudonymisationKey.primary.exists?(@primary1.id)
    refute PseudonymisationKey.primary.exists?(@secondary1.id)
    assert PseudonymisationKey.primary.exists?(@compound1.id)
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
    assert_equal [@primary1, @secondary1], @compound1.chain
  end

  test 'should be singular by default' do
    assert @primary1.singular?
    assert PseudonymisationKey.new.singular?
  end

  test 'should allow for compound keys' do
    refute @compound1.singular?
    assert @compound1.compound?

    assert_equal @primary1, @compound1.start_key
    assert_equal @secondary1, @compound1.end_key
  end

  test 'key names should be unique' do
    key = PseudonymisationKey.new(name: @primary1.name)
    refute key.valid?
    assert_includes key.errors.details[:name], error: :taken, value: key.name
  end

  test 'singular keys should not have a start or an end' do
    key = PseudonymisationKey.singular.new
    key.start_key = @primary2
    key.end_key = @secondary2

    refute key.valid?
    assert_includes key.errors.details[:start_key], error: :present
    assert_includes key.errors.details[:end_key], error: :present
  end

  test 'compound keys require a start and an end' do
    key = PseudonymisationKey.compound.new(name: 'a compound key')
    refute key.valid?
    assert_includes key.errors.details[:start_key], error: :blank
    assert_includes key.errors.details[:end_key], error: :blank

    key.start_key = @primary2
    key.end_key = @secondary2
    assert key.valid?
  end

  test 'should validate compound key chains' do
    key = PseudonymisationKey.compound.new(name: 'a wrong compound key')
    # @primary2 is not an ancestor of @secondary1:
    key.start_key = @primary2
    key.end_key = @secondary1

    refute key.valid?
    assert_includes key.errors.details[:start_key], error: :invalid

    key.start_key = @primary1
    refute key.valid?
    assert_includes key.errors.details[:start_key], error: :taken, value: @primary1
  end

  test 'compound keys should start with a primary pseudo key' do
    key = PseudonymisationKey.compound.new(name: 'a compound key')
    key.end_key = @secondary3

    key.start_key = @primary2
    key.valid?
    refute_includes key.errors.details[:start_key], error: :invalid

    key.start_key = @secondary2
    refute key.valid?
    assert_includes key.errors.details[:start_key], error: :invalid
  end

  test 'should know which users use has been granted to' do
    assert_equal [users(:test_user)], pseudonymisation_keys(:primary_one).users
  end

  test 'should be able to retrieve salts from the secrets file' do
    assert_equal %i[salt1 salt2 salt3 salt4], @primary1.salts.keys
    assert @primary1.configured?

    @primary1.name = 'not a key name'
    assert_raises(KeyError) { @primary1.salts }
    refute @primary1.configured?
  end

  test 'should be able to retrieve a salt by name or number' do
    assert @primary1.salt(1).starts_with? '660b43897f4b4e4c'
    assert @primary1.salt(:demog).starts_with? '11908217d8e5e189'

    exception = assert_raises(KeyError) { @primary1.salt(:wibble) }
    assert_match(/could not find salt: wibble/, exception.message)
  end

  test 'a singular pseudonymisation key should produce pseudoIDs' do
    pseudoid1 = @primary1.pseudoid1_for(nhs_number: '0123456789')
    assert pseudoid1.starts_with?('b549045d4aaf')

    pseudoid2 = @primary1.pseudoid2_for(birth_date: '1990-01-01', postcode: 'CB22 3AD')
    assert pseudoid2.starts_with?('a630b7aa4919')
  end

  test 'a compound pseudonymisation key should produce pseudoIDs' do
    pseudoid1 = @compound1.pseudoid1_for(nhs_number: '0123456789')
    assert pseudoid1.starts_with?('04149c7ed9f3')

    pseudoid2 = @compound1.pseudoid2_for(birth_date: '1990-01-01', postcode: 'CB22 3AD')
    assert pseudoid2.starts_with?('5c4973105c6d')
  end
end

require 'test_helper'

class IdentifiersTest < ActiveSupport::TestCase
  setup do
    @identifiers = Identifiers.new(nhs_number: '0123456789')
  end

  test 'should allow access to fields' do
    assert @identifiers.respond_to?(:nhs_number)
    assert_equal '0123456789', @identifiers.nhs_number

    refute @identifiers.respond_to?(:wibble)
    assert_raises(NoMethodError) { @identifiers.wibble }
  end

  test 'should validate NHS number' do
    assert Identifiers.new(nhs_number: '0123456789').valid?(:nhs_number)
    refute Identifiers.new(nhs_number: 'wibble').valid?(:nhs_number)
    refute Identifiers.new(nhs_number: '').valid?(:nhs_number)
  end

  test 'should validate date of birth' do
    assert Identifiers.new(birth_date: '1990-01-01').valid?(:birth_date)
    refute Identifiers.new(birth_date: '1990-21-01').valid?(:birth_date)
    refute Identifiers.new(birth_date: '').valid?(:birth_date)
  end

  test 'should validate postcode' do
    assert Identifiers.new(postcode: 'CB22 3AD').valid?(:postcode)
    refute Identifiers.new(postcode: 'CB22-3AD').valid?(:postcode)
    refute Identifiers.new(postcode: '').valid?(:postcode)
  end

  test 'should validate input_pseudoid' do
    assert Identifiers.new(input_pseudoid: SecureRandom.hex(32)).valid?(:input_pseudoid)
    refute Identifiers.new(input_pseudoid: 'not-a-pseudoid').valid?(:input_pseudoid)
    refute Identifiers.new(input_pseudoid: '').valid?(:input_pseudoid)
  end

  test 'should not validate unknown fields' do
    refute Identifiers.new(wibble: 'wobble').valid?(:wibble)
  end

  test 'should list fields missing for variants' do
    fields = { nhs_number: '0123456789' }
    assert_equal %i[], Identifiers.new(fields).missing_for_variant(1)
    assert_equal %i[birth_date postcode], Identifiers.new(fields).missing_for_variant(2)
    assert_equal %i[input_pseudoid], Identifiers.new(fields).missing_for_variant(3)

    fields.merge!(birth_date: '1990-01-01', postcode: 'CB22 3AD')
    assert_equal %i[], Identifiers.new(fields).missing_for_variant(1)
    assert_equal %i[], Identifiers.new(fields).missing_for_variant(2)
  end

  test 'should convert to a hash' do
    assert_equal({ nhs_number: '0123456789' }, @identifiers.to_h)
  end
end

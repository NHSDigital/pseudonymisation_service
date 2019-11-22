require 'test_helper'

class DemographicsTest < ActiveSupport::TestCase
  setup do
    @demographics = Demographics.new(nhs_number: '0123456789')
  end

  test 'should allow access to fields' do
    assert @demographics.respond_to?(:nhs_number)
    assert_equal '0123456789', @demographics.nhs_number

    refute @demographics.respond_to?(:wibble)
    assert_raises(NoMethodError) { @demographics.wibble }
  end

  test 'should validate NHS number' do
    assert Demographics.new(nhs_number: '0123456789').valid?(:nhs_number)
    refute Demographics.new(nhs_number: 'wibble').valid?(:nhs_number)
    refute Demographics.new(nhs_number: '').valid?(:nhs_number)
  end

  test 'should validate date of birth' do
    assert Demographics.new(birth_date: '1990-01-01').valid?(:birth_date)
    refute Demographics.new(birth_date: '1990-21-01').valid?(:birth_date)
    refute Demographics.new(birth_date: '').valid?(:birth_date)
  end

  test 'should validate postcode' do
    assert Demographics.new(postcode: 'CB22 3AD').valid?(:postcode)
    refute Demographics.new(postcode: 'CB22-3AD').valid?(:postcode)
    refute Demographics.new(postcode: '').valid?(:postcode)
  end

  test 'should not validate unknown fields' do
    refute Demographics.new(wibble: 'wobble').valid?(:wibble)
  end

  test 'should list fields missing for variants' do
    fields = { nhs_number: '0123456789' }
    assert_equal %i[], Demographics.new(fields).missing_for_variant(1)
    assert_equal %i[birth_date postcode], Demographics.new(fields).missing_for_variant(2)

    fields.merge!(birth_date: '1990-01-01', postcode: 'CB22 3AD')
    assert_equal %i[], Demographics.new(fields).missing_for_variant(1)
    assert_equal %i[], Demographics.new(fields).missing_for_variant(2)
  end

  test 'should convert to a hash' do
    assert_equal({ nhs_number: '0123456789' }, @demographics.to_h)
  end
end

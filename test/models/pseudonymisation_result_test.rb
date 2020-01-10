require 'test_helper'

class PseudonymisationResultTest < ActiveSupport::TestCase
  setup do
    @key = pseudonymisation_keys(:primary_one)
    @identifiers = Identifiers.new(nhs_number: '0123456789', birth_date: '1990-01-01', postcode: 'CB22 3AD')
  end

  test 'should produce pseudoID for the requested variant' do
    result = PseudonymisationResult.new(key: @key, variant: 1, identifiers: @identifiers, context: 'foo')
    assert result.pseudoid.starts_with?('b549045d4aaf')

    result = PseudonymisationResult.new(key: @key, variant: 2, identifiers: @identifiers, context: 'foo')
    assert result.pseudoid.starts_with?('a630b7aa4919')
  end

  test 'should error when unknown variant requested' do
    result = PseudonymisationResult.new(key: @key, variant: 'wibble', identifiers: @identifiers, context: 'foo')
    assert_raises(NotImplementedError) { result.pseudoid }
  end

  test 'should error when requested key is not configured' do
    @key.stubs(salts: {})
    result = PseudonymisationResult.new(key: @key, variant: 1, identifiers: @identifiers, context: 'foo')
    assert_raises(PseudonymisationKey::MissingSalt) { result.pseudoid }
  end

  test 'should produce hash results' do
    actual = PseudonymisationResult.new(key: @key, variant: 1, identifiers: @identifiers, context: 'foo').to_h
    expected = {
      key_name: 'Primary Key One',
      variant: 1,
      identifiers: { nhs_number: '0123456789', birth_date: '1990-01-01', postcode: 'CB22 3AD' },
      context: 'foo',
      pseudoid: 'b549045d4aaf639eaca7e543b4a725cd7bd441d3c59ecaed997786e8bb504a97'
    }

    assert_equal expected, actual
  end
end

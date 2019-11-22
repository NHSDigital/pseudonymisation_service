require 'test_helper'

class UsageLogTest < ActiveSupport::TestCase
  setup do
    path = Rails.root.join('test', 'keys', 'test_usage_log_private_key.pem')
    passphrase = 'just for testing'
    @private_key = OpenSSL::PKey::RSA.new(File.read(path), passphrase)
  end

  test 'should allow demographics to be assigned and decrypted' do
    log = UsageLog.new(demographics: { nhs_number: '0123456789' })
    assert log.encrypted_demographics.present?
    refute_match(/0123456789/, log.encrypted_demographics)
    assert_equal '0123456789', log.demographics(private_key: @private_key)[:nhs_number]
  end

  test 'should be createable from a pseudonymisation result' do
    key = pseudonymisation_keys(:primary_one)
    demographics = Demographics.new(nhs_number: '0123456789')
    result = PseudonymisationResult.new(key: key, variant: 1, demographics: demographics, context: 'foo')
    user = users(:test_user)

    log = user.usage_logs.create_from_result!(result)
    assert log.persisted?
    assert_equal 1, log.variant
    assert_equal 'foo', log.context
    assert_equal key, log.pseudonymisation_key
    assert_match(/[[:xdigit:]]{8}/, log.partial_pseudoid)
    assert_equal demographics.to_h, log.demographics(private_key: @private_key)
  end
end

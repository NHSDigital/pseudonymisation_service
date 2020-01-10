require 'test_helper'

class UsageLogTest < ActiveSupport::TestCase
  setup do
    path = Rails.root.join('test', 'keys', 'test_usage_log_private_key.pem')
    passphrase = 'just for testing'
    @private_key = OpenSSL::PKey::RSA.new(File.read(path), passphrase)

    @key = pseudonymisation_keys(:primary_one)
    @identifiers = Identifiers.new(nhs_number: '0123456789')
    result = PseudonymisationResult.new(key: @key, variant: 1, identifiers: @identifiers, context: 'foo')
    @user = users(:test_user)

    @user.usage_logs.create_from_results!([result], remote_ip: '127.0.0.1')
    @log = UsageLog.last
  end

  test 'should allow identifiers to be assigned and decrypted' do
    log = UsageLog.new(identifiers: { nhs_number: '0123456789' })
    assert log.encrypted_identifiers.present?
    refute_match(/0123456789/, log.encrypted_identifiers)
    assert_equal '0123456789', log.identifiers(private_key: @private_key)[:nhs_number]
  end

  test 'should be createable from a pseudonymisation result' do
    assert @log.persisted?
    assert_in_delta Time.current, @log.created_at, 0.1
    assert_equal 1, @log.variant
    assert_equal 'foo', @log.context
    assert_equal @user, @log.user
    assert_equal @key, @log.pseudonymisation_key
    assert_match(/[[:xdigit:]]{8}/, @log.partial_pseudoid)
    assert_equal @identifiers.to_h, @log.identifiers(private_key: @private_key)
  end

  test 'readonly - should not allow updates' do
    assert_raises(ActiveRecord::ReadOnlyRecord) do
      refute @log.update_attribute(:partial_pseudoid, 'something-else')
    end
    refute_equal 'something-else', @log.reload.partial_pseudoid
  end

  test 'readonly - should not allow destroy' do
    assert_raises(ActiveRecord::ReadOnlyRecord) { refute @log.destroy }
    assert @log.persisted?
  end
end

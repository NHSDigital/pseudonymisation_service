require 'test_helper'

class UsageLogTest < ActiveSupport::TestCase
  test 'should allow demographics to be assigned' do
    log = UsageLog.new(demographics: { nhs_number: '0123456789' })
    assert log.encrypted_demographics.present?
  end
end

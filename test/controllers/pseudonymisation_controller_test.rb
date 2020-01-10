require 'test_helper'

class PseudonymisationControllerTest < ActionDispatch::IntegrationTest
  setup do
    @key1 = pseudonymisation_keys(:primary_one)
    @key2 = pseudonymisation_keys(:primary_two)
    @rekey1 = pseudonymisation_keys(:repseudo_one)
  end

  test 'should use granted keys and variants to pseudonymise when given just NHS / DoB / postcode' do
    post_with_params
    assert_response :success

    actual = response.parsed_body
    expected = [{ 'key_name' => 'Primary Key One',
                  'variant' => 1,
                  'identifiers' => { 'nhs_number' => '0123456789', 'postcode' => 'W1A 1AA', 'birth_date' => '2000-01-01' },
                  'context' => 'testing',
                  'pseudoid' => 'b549045d4aaf639eaca7e543b4a725cd7bd441d3c59ecaed997786e8bb504a97' },
                { 'key_name' => 'Primary Key One',
                  'variant' => 2,
                  'identifiers' => { 'nhs_number' => '0123456789', 'postcode' => 'W1A 1AA', 'birth_date' => '2000-01-01' },
                  'context' => 'testing',
                  'pseudoid' => 'd7bc8a726b8110b09765db5b151b999f34b9c269301e82af6ce1d349c847374b' }]

    assert_equal expected, actual, 'should have used "Primary Key One" and variants 1 & 2'
  end

  test 'should use granted keys and variants to pseudonymise when given just NHS' do
    post_with_params identifiers: { nhs_number: '0123456789' }
    assert_response :success

    actual = response.parsed_body
    expected = [{ 'key_name' => 'Primary Key One',
                  'variant' => 1,
                  'identifiers' => { 'nhs_number' => '0123456789' },
                  'context' => 'testing',
                  'pseudoid' => 'b549045d4aaf639eaca7e543b4a725cd7bd441d3c59ecaed997786e8bb504a97' }]

    assert_equal expected, actual, 'should have used "Primary Key One" and variant 1'
  end

  test 'should use granted keys and variants to pseudonymise when given just an existing pseudoid' do
    input_pseudoid = 'd7bc8a726b8110b09765db5b151b999f34b9c269301e82af6ce1d349c847374b'
    post_with_params identifiers: { input_pseudoid: input_pseudoid }
    actual = response.parsed_body
    expected = [{ 'key_name' => 'RePseudo Key One',
                  'variant' => 3,
                  'identifiers' => { 'input_pseudoid' => input_pseudoid },
                  'context' => 'testing',
                  'pseudoid' => 'ad6f477c55ea38092d1c4f94d242c50bd130fee3e41869ee1d367b83e9cae19f' }]

    assert_equal expected, actual, 'should have used "RePseudo Key One" and variant 3'
  end

  test 'should return results for each identifier set received for bulk processing' do
    post_with_params identifiers: [{ nhs_number: '0123456789' }, { nhs_number: '1111111111' }]
    assert_response :success

    actual = response.parsed_body
    expected = [{ 'key_name' => 'Primary Key One',
                  'variant' => 1,
                  'identifiers' => { 'nhs_number' => '0123456789' },
                  'context' => 'testing',
                  'pseudoid' => 'b549045d4aaf639eaca7e543b4a725cd7bd441d3c59ecaed997786e8bb504a97' },
                { 'key_name' => 'Primary Key One',
                  'variant' => 1,
                  'identifiers' => { 'nhs_number' => '1111111111' },
                  'context' => 'testing',
                  'pseudoid' => '08f78e23b4783144726369a03289836cebff6a7e4d1b9d4d00f65e823ecf602a' }]

    assert_equal expected, actual, 'should have used "Primary Key One" and variant 1'
  end

  test 'an input issue when bulk processing should log nothing, and return no results' do
    identifiers = [{ nhs_number: '0123456789' }, { nhs_number: 'wibble' }]

    assert_no_difference(-> { UsageLog.count }) do
      post_with_params identifiers: identifiers
    end
    assert_forbidden 'no variants could be determined automatically, please specify explicitly'

    assert_no_difference(-> { UsageLog.count }) do
      post_with_params identifiers: identifiers, variants: ['1']
    end
    assert_forbidden 'missing/invalid identifiers: nhs_number'
  end

  test 'a crash when bulk processing should log nothing, and return no results' do
    assert_no_difference(-> { UsageLog.count }) do
      pseudoid = SecureRandom.hex(32)
      PseudonymisationResult.any_instance.stubs(:pseudoid).returns(pseudoid).then.raises(StandardError)
      post_with_params identifiers: [{ nhs_number: '0123456789' }, { nhs_number: '1111111111' }]
    end

    assert_response :internal_server_error
    assert response.body.blank?
  end

  test 'should create a log for each use of a pseudo key' do
    ActionDispatch::Request.any_instance.stubs(remote_ip: '127.0.0.2')
    assert_difference(-> { UsageLog.count }, 2) { post_with_params }
    assert_equal '127.0.0.2', UsageLog.first.remote_ip
  end

  test 'should fail if logging is not successful' do
    UsageLog.any_instance.stubs(user_id: nil)
    assert_no_difference(-> { UsageLog.count }) { post_with_params }
    assert_response :internal_server_error
  end

  test 'should use specified keys to pseudonymise if granted' do
    post_with_params key_names: [@key1.name]
    assert_response :success
  end

  test 'should use specified variants to pseudonymise if given' do
    post_with_params variants: ['1']
    assert_response :success
  end

  test 'should get back a result for each combination of inputs' do
    post_with_params key_names: [@key1.name], variants: ['1']
    assert_response :success
    assert_equal 1, response.parsed_body.length

    post_with_params key_names: [@key1.name], variants: %w[1 2]
    assert_response :success
    assert_equal 2, response.parsed_body.length
  end

  test 'should not allow specification of variant 1 without nhs number' do
    post_with_params variants: ['1'], identifiers: { nhs_number: '' }
    assert_forbidden 'missing/invalid identifiers: nhs_number'

    post_with_params variants: ['1'], identifiers: { birth_date: '2000-01-01' }
    assert_forbidden 'missing/invalid identifiers: nhs_number'
  end

  test 'should not allow specification of variant 2 without postcode and DoB' do
    post_with_params variants: ['2']
    assert_response :success

    post_with_params variants: ['2'], identifiers: { birth_date: '2000-01-01', postcode: 'W1A 1AA' }
    assert_response :success

    post_with_params variants: ['2'], identifiers: { birth_date: '2000-01-01' }
    assert_forbidden 'missing/invalid identifiers: postcode'

    post_with_params variants: ['2'], identifiers: { postcode: 'W1A 1AA' }
    assert_forbidden 'missing/invalid identifiers: birth_date'
  end

  test 'should not allow specification of variant 3 without pseudoid' do
    post_with_params variants: ['3'], identifiers: { input_pseudoid: SecureRandom.hex(32) }, key_names: [@rekey1.name]
    assert_response :success

    post_with_params variants: ['3'], identifiers: { nhs_number: '1111111111' }, key_names: [@rekey1.name]
    assert_forbidden 'missing/invalid identifiers: input_pseudoid'
  end

  test 'should not allow invalid variant / key combinations to be requested' do
    post_with_params variants: %w[1 2], key_names: [@rekey1.name]
    assert_forbidden 'variant 1 and 2 not appropriate for a requested pseudonymisation key'
  end

  test 'should not allow non-existent variants to be specified' do
    post_with_params variants: %w[1 wibble]
    assert_forbidden 'unavailable variant requested'
  end

  test 'should not allow requests without identifiers' do
    post_with_params identifiers: {}
    assert_forbidden "no value for 'identifiers' was supplied"
  end

  test 'should not allow requests without context' do
    post_with_params context: ''
    assert_forbidden "no value for 'context' was supplied"
  end

  test 'should not allow ungranted keys to be specified' do
    post_with_params key_names: [@key2.name]
    assert_forbidden "key 'Primary Key Two' is not available for use"
  end

  test 'should not allow non-existent keys to be specified' do
    post_with_params key_names: ['wibble']
    assert_forbidden "key 'wibble' is not available for use"
  end

  test 'when given junk identifiers without a variant, should say so' do
    post_with_params identifiers: { wibble: 'yes' }
    assert_forbidden 'no variants could be determined automatically, please specify explicitly'

    post_with_params identifiers: { wibble: 'yes' }, key_names: [@key1.name]
    assert_forbidden 'no variants could be determined automatically, please specify explicitly'

    post_with_params identifiers: { wibble: 'yes' }, variants: [1]
    assert_forbidden 'missing/invalid identifiers: nhs_number'
  end

  test 'when supplying mismatched identifiers/keys/variants, should not just return empty result set' do
    post_with_params identifiers: { nhs_number: '0123456789' }, key_names: [@rekey1.name]
    assert_forbidden 'no valid identifier/key/variant combination could be found!'

    post_with_params identifiers: { nhs_number: '0123456789' }, key_names: [@rekey1.name], variants: [1]
    assert_forbidden 'variant 1 not appropriate for a requested pseudonymisation key'

    post_with_params identifiers: { nhs_number: '0123456789' }, variants: [3]
    assert_forbidden 'missing/invalid identifiers: input_pseudoid'
  end

  test 'should error when unkown top-level params are supplied' do
    post_with_params variant: 1
    assert_forbidden 'unknown parameter(s): ["variant"]'
  end

  test 'should return any additional identifiers for linkage purposes' do
    identifiers = [
      { 'nhs_number' => '0123456789', 'patientid' => '123' },
      { 'nhs_number' => '1111111111', 'patientid' => '124' }
    ]

    post_with_params identifiers: identifiers, key_names: [@key1.name]
    assert_response :success

    data = response.parsed_body
    assert_equal(identifiers, data.map { |row| row['identifiers'] })
  end

  private

  def post_with_params(params = {})
    identifiers = { nhs_number: '0123456789', postcode: 'W1A 1AA', birth_date: '2000-01-01' }
    default_params = { context: 'testing', identifiers: identifiers }
    post pseudonymise_url, params: default_params.merge(params)
  end

  def assert_forbidden(error)
    assert_response :forbidden
    assert_includes response.parsed_body['errors'], error
  end
end

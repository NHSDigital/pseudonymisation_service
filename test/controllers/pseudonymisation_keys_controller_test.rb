require 'test_helper'

class PseudonymisationKeysControllerTest < ActionDispatch::IntegrationTest
  test 'should be accessible at an API-namespaced path' do
    assert_equal '/api/v1/keys', pseudonymisation_keys_path
  end

  test 'should list accessible keys' do
    get pseudonymisation_keys_url
    assert_response :success

    expected = PseudonymisationKey.accessible_by(current_user.ability)
    actual = response.parsed_body

    assert_equal expected.count, actual.count
    assert_equal expected.pluck(:name).sort, actual.pluck('name').sort
    assert_equal [[1, 2], [3]], actual.pluck('supported_variants').sort
  end

  test 'should not allow POST requests' do
    post pseudonymisation_keys_url
    assert_response :not_found
  end
end

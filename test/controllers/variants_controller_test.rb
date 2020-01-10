require 'test_helper'

class VariantsControllerTest < ActionDispatch::IntegrationTest
  test 'should be accessible at an API-namespaced path' do
    assert_equal '/api/v1/variants', variants_path
  end

  test 'should list accessible keys' do
    get variants_url
    assert_response :success

    expected = [
      { 'variant' => 1, 'required_identifiers' => ['nhs_number'] },
      { 'variant' => 2, 'required_identifiers' => %w[birth_date postcode] },
      { 'variant' => 3, 'required_identifiers' => ['input_pseudoid'] }
    ]
    assert_equal expected, response.parsed_body.sort_by(&:values)

    key_grants(:grant_two).destroy

    get variants_url
    assert_response :success

    expected = [
      { 'variant' => 1, 'required_identifiers' => ['nhs_number'] },
      { 'variant' => 2, 'required_identifiers' => %w[birth_date postcode] }
    ]
    assert_equal expected, response.parsed_body.sort_by(&:values)
  end

  test 'should not allow POST requests' do
    post variants_url
    assert_response :not_found
  end
end

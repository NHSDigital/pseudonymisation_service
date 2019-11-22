require 'test_helper'

class PseudonymisationControllerTest < ActionDispatch::IntegrationTest
  setup do
    @key1 = pseudonymisation_keys(:primary_one)
    @key2 = pseudonymisation_keys(:primary_two)
  end

  test 'should use granted keys and variants to pseudonymise unless specified' do
    post_with_params
    assert_response :success
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
    post_with_params variants: ['1'], demographics: { nhs_number: '' }
    assert_response :forbidden

    post_with_params variants: ['1'], demographics: { birth_date: '2000-01-01' }
    assert_response :forbidden
  end

  test 'should not allow specification of variant 2 without postcode and DoB' do
    post_with_params variants: ['2']
    assert_response :success

    post_with_params variants: ['2'], demographics: { birth_date: '2000-01-01', postcode: 'W1A 1AA' }
    assert_response :success

    post_with_params variants: ['2'], demographics: { birth_date: '2000-01-01' }
    assert_response :forbidden

    post_with_params variants: ['2'], demographics: { postcode: 'W1A 1AA' }
    assert_response :forbidden
  end

  test 'should not allow non-existent variants to be specified' do
    post_with_params variants: %w[1 wibble]
    assert_response :forbidden
  end

  test 'should not allow requests without demographics' do
    post_with_params demographics: {}
    assert_response :forbidden
  end

  test 'should not allow requests without context' do
    post_with_params context: ''
    assert_response :forbidden
  end

  test 'should not allow ungranted keys to be specified' do
    post_with_params key_names: [@key2.name]
    assert_response :forbidden
  end

  test 'should not allow non-existent keys to be specified' do
    post_with_params key_names: ['wibble']
    assert_response :forbidden
  end

  private

  def post_with_params(params = {})
    demographics = { nhs_number: '0123456789', postcode: 'W1A 1AA', birth_date: '2000-01-01' }
    default_params = { context: 'testing', demographics: demographics }
    post pseudonymise_url, params: default_params.merge(params)
  end
end

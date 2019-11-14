# Class responsible for parsing pseudonymisation request
class PseudonymisationRequestService
  # Can be raised if invalid params supplied:
  class RequestError < StandardError; end
  class MissingDemographic < RequestError; end
  class MissingKey < RequestError; end
  class UnknownKeyError < RequestError; end
  class UnknownVariantError < RequestError; end

  # Known variants, with the fields required:
  VARIANTS = {
    1 => %i[nhsnumber],
    2 => %i[birth_date postcode]
  }.freeze

  attr_reader :user, :params, :errors

  def initialize(user, params, raise_on_error: false)
    @user = user
    @params = params
    @errors = validate_params(raise_on_error)
  end

  def call
    return [false, @errors] if @errors.length.positive?

    [true, results]
  end

  private

  def validate_params(raise_on_error = false)
    list = []
    begin
      context # check context
      demographics # checks demographics
      keys # check keys
      variants # checks variants
    rescue RequestError => e
      raise e if raise_on_error

      list << e
    end
    list
  end

  def keys
    keys = PseudonymisationKey.accessible_by(user.ability)
    requested = Array(params[:key_names])
    return keys if requested.blank?

    # If a list has been specified, filter and check them:
    requested.map do |name|
      keys.detect { |key| key.name == name } || raise(UnknownKeyError, name)
    end
  end

  def context
    params[:context].presence || raise(MissingKey, :context)
  end

  def demographics
    params[:demographics].presence || raise(MissingKey, :demographics)
  end

  def variants
    variants = VARIANTS
    requested = Array(params[:variants])

    if requested.present?
      variants = requested.map.with_object({}) do |number, hash|
        variant = number.to_i
        hash[variant] = variants.fetch(variant) { raise(UnknownVariantError, number) }
      end
    end

    variants.each do |_number, required_fields|
      required_fields.each do |field|
        demographics.key?(field) || raise(MissingDemographic, field)
      end
    end

    variants
  end

  def results
    keys.flat_map do |key|
      variants.map do |variant|
        { key: key, variant: variant, context: context }
      end
    end
  end
end

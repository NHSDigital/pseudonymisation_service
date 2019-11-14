# Class responsible for parsing pseudonymisation request
class Pseudonymiser
  # Can be raised if invalid params supplied:
  class MissingContext < StandardError; end
  class UnknownKeyError < StandardError; end
  class UnknownVariantError < StandardError; end

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

  def run
    raise 'has errors!' if @errors.length.positive?

    []
  end

  private

  def validate_params(raise_on_error = false)
    list = []
    begin
      keys # check keys
      context # check context
      variants # checks variants
    rescue UnknownKeyError, MissingContext, UnknownVariantError => e
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
    params[:context].presence || raise(MissingContext)
  end

  def variants
    variants = VARIANTS
    requested = Array(params[:variants])
    return variants if requested.blank?

    requested.map do |number|
      variants.fetch(number.to_i) { raise(UnknownVariantError, number) }
    end
  end
end

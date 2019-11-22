# Class responsible for parsing pseudonymisation request
class PseudonymisationRequestService
  # Can be raised if invalid params supplied:
  class RequestError < StandardError; end
  class MissingDemographics < RequestError; end
  class MissingKey < RequestError; end
  class UnknownKeyError < RequestError; end
  class UnknownVariantError < RequestError; end

  # Known variants:
  VARIANTS = [1, 2].freeze

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
    raise(MissingKey, :demographics) if params[:demographics].blank?

    Demographics.new(params[:demographics])
  end

  def variants
    variants = Array(params[:variants]).map(&:to_i).presence || VARIANTS
    variants.each { |number| raise(UnknownVariantError) unless number.in?(VARIANTS) }

    missing = variants.flat_map { |number| demographics.missing_for_variant(number) }
    raise(MissingDemographics, missing) if missing.any?

    variants
  end

  def results
    keys.flat_map do |key|
      variants.map do |variant|
        attrs = { key: key, variant: variant, context: context, demographics: demographics }
        PseudonymisationResult.new(**attrs).to_h
      end
    end
  end
end

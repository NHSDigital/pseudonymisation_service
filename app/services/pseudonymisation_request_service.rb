# Class responsible for parsing pseudonymisation request.
#
# If explicitly given keys and variants, will ensure they
# make sense; otherwise, will determine a meaningful subset from
# what the user has access to and what demographics were supplied.
class PseudonymisationRequestService
  # Can be raised if invalid params supplied:
  class RequestError < StandardError; end

  # Raised when requested variant(s) are not compatible with one or
  # more requested pseudonymisation keys.
  class InvalidVariant < RequestError
    def initialize(variants)
      super "variant #{variants.to_sentence} not appropriate for a requested pseudonymisation key"
    end
  end

  # Raised when demographics required by a requested variant are missing,
  # or invalid:
  class MissingDemographics < RequestError
    def initialize(fields)
      super "missing/invalid demographics: #{fields.to_sentence}"
    end
  end

  # Raised when a top-level parameter is missing:
  class MissingKey < RequestError
    def initialize(key)
      super "no value for '#{key}' was supplied"
    end
  end

  # Raised when the requested keys and supplied demographics do
  # not leave any plausible variants to compute. Explicitly requesting
  # variant(s) would provide more revealing details (e.g. invalid
  # demographics information).
  class NoVariants < RequestError
    def initialize(message = nil)
      super(message || 'no variants could be determined automatically, please specify explicitly')
    end
  end

  # Raised when a pseudonymisation key either does not exist, or
  # use of a key has not been granted to the user.
  class UnknownKeyError < RequestError
    def initialize(key_name)
      super "key '#{key_name}' is not available for use"
    end
  end

  # Raised when the user's request includes unsupported parameters.
  class UnknownParameterError < RequestError
    def initialize(parameters)
      super("unknown parameter(s): #{parameters.inspect}")
    end
  end

  # Raised when the user requests variant(s) that do not exist.
  class UnknownVariantError < RequestError
    def initialize(message = nil)
      super(message || 'unavailable variant requested')
    end
  end

  # Known variants:
  VARIANTS = [1, 2, 3].freeze

  # Supported parameters
  KNOWN_PARAMETERS = %w[context demographics key_names variants].freeze

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
      check_param_keys!
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

  def check_param_keys!
    unknown_keys = params.keys - KNOWN_PARAMETERS
    raise(UnknownParameterError, unknown_keys) if unknown_keys.any?
  end

  def requested_key_names
    @requested_key_names ||= Array(params[:key_names])
  end

  def requested_keys
    @requested_keys ||= keys.select { |key| key.name.in?(requested_key_names) }
  end

  def keys
    @keys ||= begin
      keys = PseudonymisationKey.accessible_by(user.ability)
      return keys if requested_key_names.blank?

      # If a list has been specified, filter and check them:
      requested_key_names.map do |name|
        keys.detect { |key| key.name == name } || raise(UnknownKeyError, name)
      end
    end
  end

  def context
    @context ||= params[:context].presence || raise(MissingKey, :context)
  end

  def demographics
    @demographics ||= begin
      raise(MissingKey, :demographics) if params[:demographics].blank?

      DemographicsCollection.new(params[:demographics])
    end
  end

  def requested_variants
    @requested_variants ||= Array(params[:variants]).map(&:to_i)
  end

  def variants
    @variants ||= begin
      variants = requested_variants.presence || VARIANTS.dup
      variants.each { |number| raise(UnknownVariantError) unless number.in?(VARIANTS) }

      missing = requested_variants.flat_map { |number| demographics.missing_for_variant(number) }
      raise(MissingDemographics, missing) if missing.any?

      explicitly_invalid = requested_variants.select do |variant|
        requested_keys.any? && requested_keys.none? { |key| key.supports_variant?(variant) }
      end
      raise(InvalidVariant, explicitly_invalid) if explicitly_invalid.any?

      # Remove any default choices that aren't compatible with supplied demographics:
      variants.reject! { |number| demographics.missing_for_variant(number).any? }
      raise(NoVariants) if variants.none?

      unless keys.any? { |key| variants.any? { |variant| key.supports_variant?(variant) } }
        raise(NoVariants, 'no valid demographic/key/variant combination could be found!')
      end

      variants
    end
  end

  def results
    keys.each.with_object([]) do |key, results|
      variants.map do |variant|
        next unless key.supports_variant?(variant)

        demographics.each do |set|
          attrs = { key: key, variant: variant, context: context, demographics: set }
          results << PseudonymisationResult.new(**attrs)
        end
      end
    end.tap { |results| instrument(results) }
  end

  def instrument(results)
    NdrStats.count(:requests)
    NdrStats.count(:demographics, demographics.count)

    results.group_by { |r| [r.key, r.variant] }.each do |(key, variant), chunk|
      NdrStats.count(:results, chunk.length, key_name: key.name, variant: variant)
    end
  end
end

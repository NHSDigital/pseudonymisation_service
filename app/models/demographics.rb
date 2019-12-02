# Helper class to hold and validate supplied demographics
class Demographics
  # Validate format of fields:
  PATTERNS = {
    nhs_number: /\A[0-9]{10}\z/,
    postcode: /\A[A-Z0-9 ]+\z/,
    birth_date: /\A\d{4}-[01]\d-[0-3]\d\z/,
    input_pseudoid: /\A[a-z0-9]{64}\z/
  }.freeze

  # Which pseudoid variants require which fields?
  VARIANT_FIELDS = {
    1 => %i[nhs_number],
    2 => %i[birth_date postcode],
    3 => %i[input_pseudoid]
  }.freeze

  def initialize(attrs)
    @attrs = attrs
  end

  def valid?(field)
    @attrs.key?(field) && matches_any_pattern?(field)
  end

  def missing_for_variant(variant)
    VARIANT_FIELDS.fetch(variant, []).reject { |field| valid?(field) }
  end

  def to_h
    @attrs
  end

  private

  def matches_any_pattern?(field)
    value = @attrs.fetch(field)
    pattern = PATTERNS.fetch(field) { return false }

    pattern.match?(value)
  end

  def respond_to_missing?(method, include_private = false)
    @attrs.key?(method) || super
  end

  def method_missing(method, *args, &block)
    @attrs.fetch(method) { super }
  end
end

# A wrapper class responsible for holding demographics to be
# pseudonymised, facilitating that, and storing the result.
class PseudonymisationResult
  attr_reader :key, :variant, :demographics, :context

  delegate :nhs_number, :birth_date, :postcode, to: :demographics

  def initialize(key:, variant:, demographics:, context:)
    @key = key
    @variant = variant
    @demographics = demographics
    @context = context
  end

  def pseudoid
    @pseudoid ||= generate_pseudoid
  end

  def to_h
    {
      key_name: @key.name,
      variant: @variant,
      demographics: @demographics.to_h,
      context: context,
      pseudoid: pseudoid
    }
  end

  private

  def generate_pseudoid
    case variant
    when 1 then key.pseudoid1_for(nhs_number: nhs_number)
    when 2 then key.pseudoid2_for(postcode: postcode, birth_date: birth_date)
    else raise NotImplementedError
    end
  end
end

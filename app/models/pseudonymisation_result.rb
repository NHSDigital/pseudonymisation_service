# A wrapper class responsible for holding demographics to be
# pseudonymised, facilitating that, and storing the result.
class PseudonymisationResult
  attr_reader :key, :variant, :demographics, :context

  delegate :nhs_number, :birth_date, :postcode, to: :demographics
  delegate :salt, to: :key

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
    when 1 then generate_pseudoid1
    when 2 then generate_pseudoid2
    else raise NotImplementedError
    end
  end

  def generate_pseudoid1
    id, = pseudonymiser.generate_keys_nhsnumber_demog_only(salt(:id), salt(:demog), nhs_number)
    id
  end

  def generate_pseudoid2
    _id1, id2, = pseudonymiser.generate_keys(salt(:id), salt(:demog), salt(:clinical),
                                             '0123456789', postcode, birth_date)
    id2
  end

  def pseudonymiser
    NdrPseudonymise::SimplePseudonymisation
  end
end

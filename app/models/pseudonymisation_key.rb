# Represents the secret pseudonymisation keys. The actual
# secret salts are not stored in the database.
#
# Primary keys take in raw demographics, whereas secondary
# "repseudonymisation" keys operate on the output of other
# keys. This results in a tree hierarchy.
#
# Compound keys represent a chain of two or more keys composed.
class PseudonymisationKey < ApplicationRecord
  class MissingSalt < StandardError; end

  enum key_type: %i[singular compound]

  with_options class_name: 'PseudonymisationKey' do
    with_options optional: true do
      belongs_to :parent_key, inverse_of: :secondary_keys
      belongs_to :start_key
      belongs_to :end_key
    end

    has_many :secondary_keys,
             dependent: :destroy,
             foreign_key: :parent_key_id,
             inverse_of: :parent_key
  end

  has_many :usage_logs
  has_many :key_grants, dependent: :destroy
  has_many :users, through: :key_grants

  scope :singular, -> { where(key_type: :singular) }
  scope :compound, -> { where(key_type: :compound) }

  scope :primary, -> { where(parent_key_id: nil) }

  validates :name, uniqueness: true, presence: true

  with_options if: :singular?, absence: true do
    validates :start_key
    validates :end_key
  end

  with_options if: :compound? do
    validates :start_key, presence: true, uniqueness: { scope: :end_key }
    validates :end_key, presence: true

    validate :ensure_valid_chain
  end

  SALT_ID_MAP = {
    id: 1,
    demog: 2,
    clinical: 3,
    rawdata: 4,
    repseudo: 5
  }.freeze

  # What secrets are needed for each variant?
  VARIANT_SALT_MAP = {
    1 => %i[id demog],
    2 => %i[id demog clinical],
    3 => %i[repseudo]
  }.freeze

  class << self
    # All key salts are stored in environment-specific encrypted credentials
    # files, with each pseudonymisation key having an named entry.
    def salts
      Rails.application.credentials.pseudonymisation_keys
    end
  end

  def chain
    if singular?
      (parent_key&.chain || []) + [self]
    elsif compound?
      [start_key] + (end_key.chain - start_key.chain)
    end
  end

  # Each pseudonymisation key needs salt(s) to operate:
  #   salt1 is for pseudonymisation
  #   salt2 is for encrypting demographics
  #   salt3 (optional) is for encrypting clinical data
  #   salt4 (optional) is for encrypting rawtext / mixed demographics and clinical data
  #   salt5 is for repseudonymising
  def salts
    self.class.salts.fetch(name.to_sym) { raise MissingSalt }
  end

  def salt(id)
    normalised_id = SALT_ID_MAP.fetch(id, id)
    salts.fetch(:"salt#{normalised_id}") { raise MissingSalt, "missing: #{normalised_id}" }
  end

  def configured?
    salts.any?
  rescue MissingSalt
    false
  end

  def primary?
    parent_key.nil?
  end

  def secondary?
    !primary?
  end

  def supported_variants
    VARIANT_SALT_MAP.keys.select { |variant| supports_variant?(variant) }
  end

  def supports_variant?(variant)
    return start_key.supports_variant?(variant) if compound?

    ids = VARIANT_SALT_MAP.fetch(variant) { return false }
    ids.all? { |id| salt(id) }
  rescue MissingSalt
    false
  end

  def pseudoid1_for(nhs_number:)
    raise 'this key can only be used for re-pseudonymisation' unless primary?

    if singular?
      id1, = pseudonymiser.generate_keys_nhsnumber_demog_only(salt(:id), salt(:demog), nhs_number)
      id1
    else
      id1 = start_key.pseudoid1_for(nhs_number: nhs_number)
      repseudonymise(id1, chain[1..-1])
    end
  end

  def pseudoid2_for(postcode:, birth_date:)
    raise 'this key can only be used for re-pseudonymisation' unless primary?

    if singular?
      _id1, id2, = pseudonymiser.generate_keys(salt(:id), salt(:demog), salt(:clinical),
                                               '0123456789', postcode, birth_date)
      id2
    else
      id2 = start_key.pseudoid2_for(postcode: postcode, birth_date: birth_date)
      repseudonymise(id2, chain[1..-1])
    end
  end

  def pseudoid3_for(input_pseudoid:)
    keys = singular? ? [self] : chain
    repseudonymise(input_pseudoid, keys)
  end

  private

  def repseudonymise(pseudoid, keys)
    keys.each do |key|
      pseudoid = Digest::SHA2.hexdigest("pseudoid_#{pseudoid}#{key.salt(:repseudo)}")
    end

    pseudoid
  end

  def pseudonymiser
    NdrPseudonymise::SimplePseudonymisation
  end

  def ensure_valid_chain
    return unless start_key && end_key
    return if start_key.in?(end_key.chain)

    errors.add(:start_key, :invalid)
  end
end

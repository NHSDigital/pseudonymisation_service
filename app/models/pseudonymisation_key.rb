# Represents the secret pseudonymisation keys. The actual
# secrets are not stored in the database.
#
# Primary keys take in raw demographics, whereas secondary
# "repseudonymisation" keys operate on the output of other
# keys. This results in a tree hierarchy.
#
# Compound keys represent a chain of two or more keys composed.
class PseudonymisationKey < ApplicationRecord
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

  scope :primary, -> { singular.where(parent_key_id: nil) }
  scope :secondary, -> { singular.where.not(parent_key_id: nil) }

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

  def chain
    if singular?
      (parent_key&.chain || []) + [self]
    elsif compound?
      [start_key] + (end_key.chain - start_key.chain)
    end
  end

  private

  def ensure_valid_chain
    return unless start_key && end_key
    return if start_key.in?(end_key.chain)

    errors.add(:start_key, :invalid)
  end
end

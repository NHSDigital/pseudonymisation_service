# Represents the secret pseudonymisation keys. The actual
# secrets are not stored in the database.
#
# Primary keys take in raw demographics, whereas secondary
# "repseudonymisation" keys operate on the output of other
# keys. This results in a tree hierarchy.
class PseudonymisationKey < ApplicationRecord
  belongs_to :parent_key,
             class_name: 'PseudonymisationKey',
             inverse_of: :secondary_keys,
             optional: true

  has_many :secondary_keys,
           class_name: 'PseudonymisationKey',
           foreign_key: :parent_key_id,
           inverse_of: :parent_key

  scope :primary, -> { where(parent_key_id: nil) }
  scope :secondary, -> { where.not(parent_key_id: nil) }

  def chain
    (parent_key&.chain || []) + [self]
  end
end

# The presence of a KeyGrant allow a user to make use
# of a pseudonymisation key, be it singular or compound.
class KeyGrant < ApplicationRecord
  belongs_to :user
  belongs_to :pseudonymisation_key

  validates :user, uniqueness: { scope: :pseudonymisation_key }
end

# Stores an audit log of all pseudonymisation actions made by users.
# For retrieval, a partial pseudoid is stored (and thus useable for
# filtering) alongside public key-encrypted demographics.
class UsageLog < ApplicationRecord
  belongs_to :user
  belongs_to :pseudonymisation_key

  class << self
    def create_from_result!(result)
      create!(
        demographics: result.demographics.to_h,
        pseudonymisation_key: result.key,
        partial_pseudoid: result.pseudoid.slice(0...8),
        variant: result.variant,
        context: result.context
      )
    end
  end

  def demographics
    private_decrypt(encrypted_demographics)
  end

  def demographics=(demographics)
    self.encrypted_demographics = public_encrypt(demographics)
  end

  private

  def public_encrypt(data)
    JSON.dump(data)
  end

  def private_decrypt(ciphertext)
    JSON.parse(ciphertext).symbolize_keys
  end
end

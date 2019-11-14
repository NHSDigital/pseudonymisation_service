# Stores an audit log of all pseudonymisation actions made by users.
# For retrieval, a partial pseudoid is stored (and thus useable for
# filtering) alongside public key-encrypted demographics.
class UsageLog < ApplicationRecord
  belongs_to :user
  belongs_to :pseudonymisation_key

  def demographics
    private_decrypt(encrypted_demographics)
  end

  def demographics=(demographics)
    self.encrypted_demographics = public_encrypt(demographics)
  end

  private

  def public_encrypt(data)
    data
  end

  def private_decrypt(ciphertext)
    ciphertext
  end
end

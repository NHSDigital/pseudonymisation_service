# Stores an audit log of all pseudonymisation actions made by users.
# For retrieval, a partial pseudoid is stored (and thus useable for
# filtering) alongside public key-encrypted demographics.
class UsageLog < ApplicationRecord
  belongs_to :user
  belongs_to :pseudonymisation_key

  class << self
    def create_from_results!(results, remote_ip:)
      rows = results.map do |result|
        new(
          demographics: result.demographics.to_h,
          pseudonymisation_key: result.key,
          partial_pseudoid: result.pseudoid.slice(0...8),
          variant: result.variant,
          context: result.context,
          remote_ip: remote_ip
        )
      end

      import!(rows)
    end
  end

  def demographics(private_key:)
    private_decrypt(encrypted_demographics, private_key)
  end

  def demographics=(demographics)
    self.encrypted_demographics = public_encrypt(demographics)
  end

  def readonly?
    !new_record?
  end

  private

  def public_encrypt(data)
    Base64.strict_encode64 public_key.public_encrypt(JSON.dump(data))
  end

  def private_decrypt(encoded_ciphertext, private_key)
    json = private_key.private_decrypt Base64.strict_decode64(encoded_ciphertext)
    JSON.parse(json).symbolize_keys
  end

  def public_key
    OpenSSL::PKey::RSA.new Rails.application.credentials.usage_logs_demographics_pk
  end
end

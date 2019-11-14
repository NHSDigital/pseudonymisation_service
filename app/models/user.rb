# Model to represent users of the API.
# Users can be created using:
#
#   $ rails users:create
#
class User < ApplicationRecord
  has_many :usage_logs
  has_many :key_grants, dependent: :destroy
  has_many :pseudonymisation_keys, through: :key_grants

  # Looks up the given token in the userlist,
  # and returns the corresponding model.
  def self.retrieve_by(token:)
    username = Userlist.find_by(token: token)
    find_by(username: username) if username.present?
  end

  def ability
    Ability.new(self)
  end
end

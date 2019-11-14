# Model to represent users of the API.
# Users can be created using:
#
#   $ rails users:create
#
class User < ApplicationRecord
  # Looks up the given token in the userlist,
  # and returns the corresponding model.
  def self.retrieve_by(token:)
    username = Userlist.find_by(token: token)
    find_by(username: username) if username.present?
  end
end

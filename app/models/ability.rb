# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user.persisted?

    # A user can see keys to which access has been granted:
    can :read, PseudonymisationKey, key_grants: { user_id: user.id }
  end
end

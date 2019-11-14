# Controller to handle the actual pseudonymisation operation.
class PseudonymisationController < ApplicationController

  # POST /api/v1/pseudonymise
  def pseudonymise
    pseudonymiser = Pseudonymiser.new(current_user, params)

    if pseudonymiser.errors.none?
      render json: pseudonymiser.run
    else
      render status: :forbidden
    end
  end
end

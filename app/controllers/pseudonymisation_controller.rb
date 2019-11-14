# Controller to handle the actual pseudonymisation operation.
class PseudonymisationController < ApplicationController

  # POST /api/v1/pseudonymise
  def pseudonymise
    service = PseudonymisationRequestService.new(current_user, params)
    success, output = service.call

    if success
      render json: output
    else
      render status: :forbidden # + output info
    end
  end
end

# Controller to handle the actual pseudonymisation operation.
class PseudonymisationController < ApplicationController
  # POST /api/v1/pseudonymise
  def pseudonymise
    service = PseudonymisationRequestService.new(current_user, params)
    success, output = service.call

    if success
      render json: log_and_transform(output)
    else
      render json: { errors: output }, status: :forbidden
    end
  end

  private

  def log_and_transform(output)
    current_user.transaction do
      output.map do |result|
        current_user.usage_logs.create_from_result!(result, remote_ip: request.remote_ip)
        result.to_h
      end
    end
  end
end

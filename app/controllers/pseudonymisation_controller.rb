# Controller to handle the actual pseudonymisation operation.
class PseudonymisationController < ApplicationController
  # POST /api/v1/pseudonymise
  def pseudonymise
    service = PseudonymisationRequestService.new(current_user, raw_params)
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
      current_user.usage_logs.create_from_results!(output, remote_ip: request.remote_ip)
      output.map(&:to_h)
    end
  end

  def raw_params
    params.except('controller', 'action')
  end
end

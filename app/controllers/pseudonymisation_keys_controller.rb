# Controller to list available keys back to the user.
class PseudonymisationKeysController < ApplicationController
  load_and_authorize_resource

  # GET /api/v1/keys
  def index
    render json: @pseudonymisation_keys
  end
end

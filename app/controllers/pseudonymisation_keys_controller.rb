# Controller to list available keys back to the user.
class PseudonymisationKeysController < ApplicationController
  load_and_authorize_resource

  # GET /api/v1/keys
  def index
    items = @pseudonymisation_keys.map do |key|
      { name: key.name, supported_variants: key.supported_variants }
    end
    render json: items
  end
end

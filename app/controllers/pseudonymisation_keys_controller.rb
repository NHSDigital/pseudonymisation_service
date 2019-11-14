class PseudonymisationKeysController < ApplicationController
  load_and_authorize_resource

  def index
    render json: @pseudonymisation_keys
  end
end

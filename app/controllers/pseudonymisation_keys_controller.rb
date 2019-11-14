class PseudonymisationKeysController < ApplicationController
  # cancancan
  # jbuilder
  def index
    render json: PseudonymisationKey.all
  end
end

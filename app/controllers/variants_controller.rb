# Controller to list available variants back to the user.
class VariantsController < ApplicationController
  load_and_authorize_resource :pseudonymisation_keys, parent: false

  # GET /api/v1/variants
  def index
    variants = @pseudonymisation_keys.flat_map(&:supported_variants).uniq

    items = variants.map do |variant|
      { variant: variant, required_demographics: Demographics::VARIANT_FIELDS.fetch(variant) }
    end

    render json: items
  end
end

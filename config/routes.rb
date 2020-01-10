Rails.application.routes.draw do
  scope '/api/v1' do
    # List available keys:
    get '/keys', to: 'pseudonymisation_keys#index', as: :pseudonymisation_keys

    # List available variants:
    get '/variants', to: 'variants#index', as: :variants

    # Perform Pseudonymisation:
    post '/pseudonymise', to: 'pseudonymisation#pseudonymise'
  end

  root 'application#info'
end

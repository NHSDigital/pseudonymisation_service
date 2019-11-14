Rails.application.routes.draw do
  scope '/api/v1' do
    # List available keys:
    get '/keys', to: 'pseudonymisation_keys#index', as: :pseudonymisation_keys

    # Perform Pseudonymisation:
    post '/pseudonymise', to: 'pseudonymisation#pseudonymise'
  end

  root 'application#info'
end

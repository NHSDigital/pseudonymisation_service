Rails.application.routes.draw do
  scope '/api/v1' do
    get '/keys', to: 'pseudonymisation_keys#index', as: :pseudonymisation_keys
  end

  root 'application#info'
end

namespace :users do
  desc 'Generates a new token for a user'
  task generate_token: :environment do
    require 'highline/import'

    username = ask('Username:') { |q| q.validate = /\w+/ }
    token = SecureRandom.hex(32)

    Userlist.add(name: username, token: token)

    puts <<~MESSAGE
      The following token has been generated for #{username}:

      #{token}

      A hashed version has been added to:

      #{Userlist.path}

      It will not be accessible again once this output is cleared.
    MESSAGE
  end
end

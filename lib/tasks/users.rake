require 'highline/import'

namespace :users do
  desc 'Creates a new user'
  task create: :environment do
    username = ask('Username:') { |q| q.validate = /\w+/ }
    user = User.create!(username: username)

    Rake::Task['users:generate_token'].invoke(user.username)
  end

  desc 'Generates a new token for a user'
  task :generate_token, [:username] => :environment do |_task, args|
    username = args.fetch(:username) do
      ask('Username:') { |q| q.validate = /\w+/ }
    end
    user = User.find_by!(username: username)

    raise('no user found with that username!') unless user

    token = SecureRandom.hex(32)
    Userlist.add(name: user.username, token: token)

    puts <<~MESSAGE
      The following token has been generated for #{user.username}:

      #{token}

      A hashed version has been added to:

      #{Userlist.path}

      It will not be accessible again once this output is cleared.
    MESSAGE
  end
end

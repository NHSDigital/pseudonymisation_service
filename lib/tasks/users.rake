require 'highline/import'

namespace :users do
  desc 'Creates a new user'
  task create: :environment do
    username = ask('Username:') { |q| q.validate = /\w+/ }
    user = User.create!(username: username)

    puts "User #{user.username} created."

    Rake::Task['users:generate_token'].invoke(user.username)
    Rake::Task['users:grants:add'].invoke(user.username)
  end

  desc 'Generates a new token for a user'
  task :generate_token, [:username] => :environment do |_task, args|
    username = args.fetch(:username) do
      ask('Username:') { |q| q.validate = /\w+/ }
    end
    user = User.find_by!(username: username)

    token = SecureRandom.hex(32)
    Userlist.add(name: user.username, token: token)

    puts <<~MESSAGE
      The following token has been generated for #{user.username}:

      #{user.username}:#{token}

      A hashed version has been added to:

      #{Userlist.path}

      It will not be accessible again once this output is cleared.
    MESSAGE
  end

  namespace :grants do
    desc 'Lists pseudonymisation key grants for a user'
    task :list, [:username] => :environment do |_task, args|
      username = args.fetch(:username) do
        ask('Username:') { |q| q.validate = /\w+/ }
      end
      user = User.find_by!(username: username)

      puts "User #{user.username} has usage of the following key(s):"
      user.pseudonymisation_keys.each do |key|
        puts "  - #{key.id}: #{key.name}"
      end
    end

    desc 'Add a new pseudonymisation key grant for a user'
    task :add, [:username] => :environment do |_task, args|
      username = args.fetch(:username) do
        ask('Username:') { |q| q.validate = /\w+/ }
      end
      user = User.find_by!(username: username)

      ungranted_keys = PseudonymisationKey.primary - user.pseudonymisation_keys
      if ungranted_keys.none?
        puts 'No more keys to grant!'
        next
      end

      choose do |menu|
        menu.prompt = "Choose a new key to grant to #{user.username}:"

        ungranted_keys.each do |key|
          menu.choice(key.name) do
            user.key_grants.create!(pseudonymisation_key: key)
            puts "User #{user.username} has been granted use of key #{key.name}"
          end
        end
        menu.choice('(cancel)') { exit }
      end

      Rake::Task['users:grants:list'].invoke(user.username)
    end

    desc 'Revoke a pseudonymisation key grant from a user'
    task :revoke, [:username] => :environment do |_task, args|
      username = args.fetch(:username) do
        ask('Username:') { |q| q.validate = /\w+/ }
      end
      user = User.find_by!(username: username)

      if user.pseudonymisation_keys.none?
        puts 'No keys granted!'
        next
      end

      choose do |menu|
        menu.prompt = "Choose a key to revoke from #{user.username}:"

        user.pseudonymisation_keys.each do |key|
          menu.choice(key.name) do
            user.key_grants.where(pseudonymisation_key: key).delete_all
            puts "Key #{key.name} revoked from #{user.username}"
          end
        end
        menu.choice('(cancel)') { exit }
      end

      Rake::Task['users:grants:list'].invoke(user.username)
    end
  end
end

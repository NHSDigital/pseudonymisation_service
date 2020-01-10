require 'bundler/capistrano'
require 'ndr_dev_support/capistrano/ndr_model'

set :application, 'pseudonymisation_service'
set :repository_branches, 'https://deepthought/svn/'

# Exclude these files from the deployment:
set :copy_exclude, %w[
  .ruby-version
  .git/*
  .svn/*
  config/deploy.rb
  test/*
]

# Exclude gems from these bundler groups:
set :bundle_without, %i[development test]

# Custom shared paths, as we use credentials:
set :shared_paths, %w[config/database.yml config/credentials.yml.enc log tmp]

set :synchronise_sysadmin_scripts, true

# This is an API-only application, so doesn't have any assets:
set :asset_script, 'true'

before 'ndr_dev_support:update_out_of_bundle_gems' do
  set :out_of_bundle_gems, webapp_deployment ? %w[puma nio4r] : %w[]
end

namespace :bundle do
  desc 'Ensure bundler is properly configured'
  task :configure do
    # We need to use local configuration, because global configuration will be "global" for the
    # deploying user, rather than the application user.
    run <<~SHELL
      cd #{release_path} && bundle config --local build.pg --with-pg-config=/usr/pgsql-11/bin/pg_config
    SHELL
  end
end
before 'bundle:install', 'bundle:configure'

TARGETS = [
  # env,   name,         app,     port,   app_user,     is_web_server
  [:live, :pseudo_live, 'hermes', 28000, 'pseudo_live', true],
]

TARGETS.each do |env, name, app, port, app_user, is_web_server|
  add_target(env, name, app, port, app_user, is_web_server)
end

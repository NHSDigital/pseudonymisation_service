# Avoid spurious deprecation warning on STDERR with capistrano 2 and bundler 2.x
set :bundle_cmd, 'BUNDLE_SILENCE_DEPRECATIONS=true bundle'

require 'bundler/capistrano'
require 'ndr_dev_support/capistrano/ndr_model'

set :application, 'pseudonymisation_service'
set :repository, 'https://github.com/publichealthengland/pseudonymisation_service'
set :scm, :git

# Exclude these files from the deployment:
set :copy_exclude, %w[
  .ruby-version
  .git/*
  .svn/*
  config/deploy.rb
  test/*
  vendor/cache/*-arm64-darwin.gem
  vendor/cache/*-x86_64-darwin.gem
]

# Exclude gems from these bundler groups:
set :bundle_without, %i[development test]

# Custom shared paths, as we use credentials:
set :shared_paths, %w[config/database.yml config/credentials.yml.enc config/userlist.yml log tmp]

set :synchronise_sysadmin_scripts, true

# This is an API-only application, so doesn't have any assets:
set :asset_script, 'true'

before 'ndr_dev_support:update_out_of_bundle_gems' do
  set :out_of_bundle_gems, webapp_deployment ? %w[puma puma-daemon rack nio4r] : %w[]
end

namespace :ndr_dev_support do
  task :remove_svn_cache_if_needed do
    # no-op now we're using GitHub / branches
  end
end

desc 'ensure additional configuration for CentOS deployments'
task :centos_deployment_specifics do
  # We'd like to do the following, but scl incorrectly handles double quotes in passed commands:
  # set :default_shell, 'scl enable devtoolset-9 -- sh'
  set :default_shell, <<~CMD.chomp
    sh -c 'scl_run() { echo "$@" | scl enable devtoolset-9 -; }; scl_run "$@"'
  CMD
end

namespace :bundle do
  desc 'Ensure bundler is properly configured'
  task :configure do
    # We need to use local configuration, because global configuration will be "global" for the
    # deploying user, rather than the application user.
    # You can override the path using e.g. set :pg_conf_path, '/usr/pgsql-9.5/bin/pg_config'
    # otherwise the latest installed version will be used.
    # Note that the relevant postgresql-devel package is required, not just postgresql
    run <<~SHELL
      set -e;
      cd #{release_path};
      pg_conf_path="#{fetch(:pg_conf_path, '')}";
      if [ -z "$pg_conf_path" ]; then
        pg_conf_path=`ls -1d /usr/pgsql-{9*,[1-8]*}/include 2> /dev/null | sed -e 's:/include$:/bin/pg_config:' | tail -1`;
      fi;
      if [ -n "$pg_conf_path" ]; then
        echo Using pg_conf_path=\\"$pg_conf_path\\";
        bundle config --local build.pg --with-pg-config="$pg_conf_path";
      fi
    SHELL
  end
end
before 'bundle:install', 'bundle:configure'

TARGETS = [
  # env,   name,         app,        port,   app_user,     is_web_server
  [:live, :pseudo_live, 'localhost', 28000, 'pseudo_live', true],
]

TARGETS.each do |env, name, app, port, app_user, is_web_server|
  add_target(env, name, app, port, app_user, is_web_server)
end

%i[pseudo_live].each do |name|
  after name, 'centos_deployment_specifics'
end

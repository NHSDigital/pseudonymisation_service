namespace :credentials do
  desc 'Ensures credentials can be read'
  task unlock: :environment do
    require 'highline'
    cli = HighLine.new

    while Rails.application.credentials.key.blank?
      ENV['RAILS_MASTER_KEY'] = cli.ask('RAILS_MASTER_KEY: ') { |q| q.echo = false }
    end
  end
end

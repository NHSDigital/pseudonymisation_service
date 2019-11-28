# Users allowed to authenticate with the API have hashed tokens
# stored in a YAML file at `Rails.configuration.userlist_path`.
#
# This module handles reading/writing/checking that file.
module Userlist
  extend self

  def list
    @list ||= read
  end

  def find_by(token:)
    name, token = token.split(':', 2)
    hash = list.fetch(name) { return nil }

    name if BCrypt::Password.new(hash) == token
  end

  def add(name:, token:)
    write list.merge(name => BCrypt::Password.create(token).to_s)
  end

  def path
    Rails.configuration.userlist_path
  end

  private

  def read
    @list = nil
    File.exist?(path) && YAML.load_file(path) || {}
  end

  def write(list)
    backup(path)
    File.write(path, list.to_yaml)
  end

  def backup(path)
    return unless File.exist?(path)

    backup_path = "#{path}.#{Time.current.strftime('%Y%m%d%H%M%S')}.bk"
    FileUtils.cp(path, backup_path)
  end
end

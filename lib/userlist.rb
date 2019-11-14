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
    user = nil
    list.each do |name, hash|
      user = name if BCrypt::Password.new(hash) == token
    end
    user
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
    File.exist?(path) ? YAML.load_file(path) : {}
  end

  def write(list)
    File.write(path, list.to_yaml)
  end
end

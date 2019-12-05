# Users allowed to authenticate with the API have hashed tokens
# stored in a YAML file at `Rails.configuration.userlist_path`.
#
# This module handles reading/writing/checking that file.
#
# Successful token lookups are cached, so that the process in
# question can more rapidly re-authenticate valid users - a bcrypt
# hash comparison adds ~200ms to the request.
module Userlist
  extend self

  def list(force_read: stale?)
    if force_read
      token_cache(clear: false)
      @list = nil
    end

    @list ||= read
  end

  def find_by(token:)
    name, token = token.split(':', 2)
    hash = list.fetch(name) { return nil }

    name if token_matches_hash?(token, hash)
  end

  def add(name:, token:)
    write list.merge(name => BCrypt::Password.create(token).to_s)
  end

  def path
    Rails.configuration.userlist_path
  end

  def token_cache(clear: false)
    @token_cache = nil if clear || stale?
    @token_cache ||= Set.new
  end

  private

  def read
    @list = nil
    return {} unless File.exist?(path)

    @read_at = Time.current
    YAML.load_file(path)
  end

  def stale?
    return true unless @read_at

    File.exist?(path) && File.mtime(path) > @read_at
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

  def token_matches_hash?(token, hash)
    key = [token, hash]

    return true if token_cache.include?(key)
    return false unless BCrypt::Password.new(hash) == token

    token_cache << key
  end
end

class RenameEncryptedDemographics < ActiveRecord::Migration[6.0]
  def change
    rename_column :usage_logs, :encrypted_demographics, :encrypted_identifiers
  end
end

class AddRemoteIpToUsageLogs < ActiveRecord::Migration[6.0]
  def change
    add_column :usage_logs, :remote_ip, :string, null: false
  end
end

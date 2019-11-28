# Adds missing timestamp column to the USAGE_LOGS table.
class AddTimestampsToUsageLogs < ActiveRecord::Migration[6.0]
  def change
    add_column :usage_logs, :created_at, :datetime, null: false, precision: 6
  end
end

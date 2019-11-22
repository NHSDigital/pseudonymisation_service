class AddVariantToUsageLogs < ActiveRecord::Migration[6.0]
  def change
    add_column :usage_logs, :variant, :integer, null: false

    change_column_null :usage_logs, :partial_pseudoid, false
    change_column_null :usage_logs, :encrypted_demographics, false
    change_column_null :usage_logs, :context, false
  end
end

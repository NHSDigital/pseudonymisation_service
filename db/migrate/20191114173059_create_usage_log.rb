class CreateUsageLog < ActiveRecord::Migration[6.0]
  def change
    create_table :usage_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :pseudonymisation_key, null: false, foreign_key: true
      t.string :partial_pseudoid
      t.text :encrypted_demographics
      t.string :context
    end
    add_index :usage_logs, :partial_pseudoid
  end
end

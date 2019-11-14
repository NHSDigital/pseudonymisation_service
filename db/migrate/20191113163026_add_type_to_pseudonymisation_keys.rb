# Enables pseudonymisation keys to be composed into compound keys.
class AddTypeToPseudonymisationKeys < ActiveRecord::Migration[6.0]
  def change
    change_table :pseudonymisation_keys, bulk: true do |t|
      t.integer :key_type, default: 0, null: false

      t.bigint :start_key_id, index: true
      t.bigint :end_key_id, index: true

      t.foreign_key :pseudonymisation_keys, column: :start_key_id
      t.foreign_key :pseudonymisation_keys, column: :end_key_id
    end
  end
end

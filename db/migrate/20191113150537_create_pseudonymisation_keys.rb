class CreatePseudonymisationKeys < ActiveRecord::Migration[6.0]
  def change
    create_table :pseudonymisation_keys do |t|
      t.string :name
      t.bigint :parent_key_id

      t.timestamps
    end

    add_foreign_key :pseudonymisation_keys, :pseudonymisation_keys, column: :parent_key_id

    add_index :pseudonymisation_keys, :name, unique: true
    add_index :pseudonymisation_keys, :parent_key_id
  end
end

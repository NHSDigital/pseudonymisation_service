class CreateKeyGrants < ActiveRecord::Migration[6.0]
  def change
    create_table :key_grants do |t|
      t.references :user, null: false, foreign_key: true
      t.references :pseudonymisation_key, null: false, foreign_key: true

      t.timestamps
    end

    # Add compound unique constraint:
    add_index :key_grants, [:user_id, :pseudonymisation_key_id], unique: true
  end
end

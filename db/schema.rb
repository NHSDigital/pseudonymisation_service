# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_11_13_173602) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "key_grants", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "pseudonymisation_key_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["pseudonymisation_key_id"], name: "index_key_grants_on_pseudonymisation_key_id"
    t.index ["user_id", "pseudonymisation_key_id"], name: "index_key_grants_on_user_id_and_pseudonymisation_key_id", unique: true
    t.index ["user_id"], name: "index_key_grants_on_user_id"
  end

  create_table "pseudonymisation_keys", force: :cascade do |t|
    t.string "name"
    t.bigint "parent_key_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "key_type", default: 0, null: false
    t.bigint "start_key_id"
    t.bigint "end_key_id"
    t.index ["end_key_id"], name: "index_pseudonymisation_keys_on_end_key_id"
    t.index ["name"], name: "index_pseudonymisation_keys_on_name", unique: true
    t.index ["parent_key_id"], name: "index_pseudonymisation_keys_on_parent_key_id"
    t.index ["start_key_id"], name: "index_pseudonymisation_keys_on_start_key_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "username", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "key_grants", "pseudonymisation_keys"
  add_foreign_key "key_grants", "users"
  add_foreign_key "pseudonymisation_keys", "pseudonymisation_keys", column: "end_key_id"
  add_foreign_key "pseudonymisation_keys", "pseudonymisation_keys", column: "parent_key_id"
  add_foreign_key "pseudonymisation_keys", "pseudonymisation_keys", column: "start_key_id"
end

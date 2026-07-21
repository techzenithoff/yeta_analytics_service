# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2025_10_29_125946) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "watch_histories", force: :cascade do |t|
    t.uuid "uuid", null: false
    t.string "watchable_type"
    t.bigint "watchable_id"
    t.bigint "account_id", null: false
    t.datetime "started_at"
    t.datetime "last_watched_at"
    t.integer "position_seconds"
    t.integer "duration_seconds"
    t.boolean "completed"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["account_id"], name: "index_watch_histories_on_account_id"
    t.index ["watchable_type", "watchable_id"], name: "index_watch_histories_on_watchable"
  end

end

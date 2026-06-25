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

ActiveRecord::Schema[8.1].define(version: 2026_06_25_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "contracts", primary_key: "record_id", id: :serial, force: :cascade do |t|
    t.decimal "amount", precision: 15, scale: 2
    t.datetime "award_date"
    t.boolean "calculation_completed", default: false, null: false
    t.string "cpv_code"
    t.string "cpv_description"
    t.string "currency"
    t.string "description"
    t.datetime "end_date"
    t.datetime "expired_date_time"
    t.boolean "expired_record", default: false, null: false
    t.string "notice_type"
    t.string "ocid"
    t.string "organisation_id"
    t.string "organisation_name"
    t.datetime "published_date"
    t.datetime "record_inserted_date"
    t.string "source_api"
    t.datetime "start_date"
    t.string "tender_id"
    t.datetime "tender_period_end_date"
    t.string "title"
    t.index ["expired_record"], name: "index_contracts_on_expired_record"
    t.index ["ocid"], name: "index_contracts_on_ocid"
    t.index ["organisation_id"], name: "index_contracts_on_organisation_id"
    t.index ["tender_id"], name: "index_contracts_on_tender_id"
  end
end

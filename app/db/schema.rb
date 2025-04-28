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

ActiveRecord::Schema[7.1].define(version: 2025_04_25_174121) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "addresses", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.string "street"
    t.string "city"
    t.string "region"
    t.string "postal_code"
    t.string "country"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["patient_id"], name: "index_addresses_on_patient_id", unique: true
  end

  create_table "hospitals", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_hospitals_on_code", unique: true
  end

  create_table "imports", force: :cascade do |t|
    t.bigint "hospital_id", null: false
    t.string "name", null: false
    t.text "yaml_content", null: false
    t.string "file_key"
    t.string "status", default: "pending", null: false
    t.integer "row_count", default: 0
    t.integer "error_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "import_type", null: false
    t.jsonb "error_logs", default: []
    t.float "time_taken", default: 0.0
    t.index ["hospital_id"], name: "index_imports_on_hospital_id"
    t.index ["name", "hospital_id"], name: "index_imports_on_name_and_hospital_id", unique: true
  end

  create_table "patients", force: :cascade do |t|
    t.string "medical_record_number", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email"
    t.string "phone_number"
    t.date "date_of_birth"
    t.string "gender"
    t.bigint "hospital_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hospital_id"], name: "index_patients_on_hospital_id"
    t.index ["medical_record_number", "hospital_id"], name: "index_patients_on_mrn_and_hospital_id", unique: true
  end

  create_table "vitals", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.string "vital_type", null: false
    t.decimal "measurement", precision: 10, scale: 2, null: false
    t.string "unit", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["patient_id"], name: "index_vitals_on_patient_id"
  end

  add_foreign_key "addresses", "patients"
  add_foreign_key "imports", "hospitals"
  add_foreign_key "patients", "hospitals"
  add_foreign_key "vitals", "patients"
end

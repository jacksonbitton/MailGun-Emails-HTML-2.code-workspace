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

ActiveRecord::Schema[7.0].define(version: 2025_09_16_232407) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "account_owners", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "user_id", null: false
    t.string "tag"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_account_owners_on_company_id"
    t.index ["user_id"], name: "index_account_owners_on_user_id"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "bays", force: :cascade do |t|
    t.string "name"
    t.bigint "location_id", null: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_bays_on_location_id"
    t.index ["user_id"], name: "index_bays_on_user_id"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: true, null: false
    t.text "search"
  end

  create_table "employee_display_settings", force: :cascade do |t|
    t.bigint "location_id", null: false
    t.bigint "company_id", null: false
    t.text "visible_location_users"
    t.text "hidden_company_users"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_employee_display_settings_on_company_id"
    t.index ["location_id"], name: "index_employee_display_settings_on_location_id"
  end

  create_table "equipment", force: :cascade do |t|
    t.text "name"
    t.integer "order", null: false
    t.string "equipment_type", default: "standard", null: false
    t.bigint "bay_id", null: false
    t.bigint "location_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bay_id"], name: "index_equipment_on_bay_id"
    t.index ["location_id"], name: "index_equipment_on_location_id"
    t.index ["user_id"], name: "index_equipment_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.datetime "start_time", null: false
    t.datetime "end_time", null: false
    t.bigint "user_id", null: false
    t.string "type", null: false
    t.integer "status", default: 0
    t.integer "shift_type"
    t.bigint "location_id"
    t.text "description"
    t.boolean "exclude_from_weekly_hours", default: false
    t.json "days_applied", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "participants", default: [], array: true
    t.string "title"
    t.boolean "schedule_all_employees", default: false
    t.boolean "include_in_weekly_hours", default: false
    t.boolean "publish_status", default: false
    t.bigint "shift_type_id"
    t.datetime "reviewed_at"
    t.bigint "reviewed_by_id"
    t.index ["location_id"], name: "index_events_on_location_id"
    t.index ["reviewed_by_id"], name: "index_events_on_reviewed_by_id"
    t.index ["shift_type_id"], name: "index_events_on_shift_type_id"
    t.index ["user_id"], name: "index_events_on_user_id"
  end

  create_table "flipper_features", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "histories", force: :cascade do |t|
    t.integer "change_type", null: false
    t.text "description"
    t.string "status"
    t.string "historable_type", null: false
    t.bigint "historable_id", null: false
    t.bigint "created_by_id"
    t.bigint "version_id"
    t.bigint "equipment_id", null: false
    t.bigint "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_histories_on_created_by_id"
    t.index ["equipment_id"], name: "index_histories_on_equipment_id"
    t.index ["historable_type", "historable_id"], name: "index_histories_on_historable"
    t.index ["parent_id"], name: "index_histories_on_parent_id"
    t.index ["version_id"], name: "index_histories_on_version_id"
  end

  create_table "incidents", force: :cascade do |t|
    t.string "customer_name", null: false
    t.string "phone", null: false
    t.string "email", null: false
    t.boolean "member", null: false
    t.string "vin", null: false
    t.string "plate", null: false
    t.string "state", null: false
    t.integer "year", null: false
    t.string "make", null: false
    t.string "model", null: false
    t.string "color", null: false
    t.string "incident_area", null: false
    t.date "incident_date", null: false
    t.string "incident_time", null: false
    t.integer "status", default: 0, null: false
    t.bigint "location_id", null: false
    t.bigint "user_id"
    t.bigint "assigned_to_id"
    t.text "search"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_to_id"], name: "index_incidents_on_assigned_to_id"
    t.index ["location_id"], name: "index_incidents_on_location_id"
    t.index ["user_id"], name: "index_incidents_on_user_id"
  end

  create_table "inspections", force: :cascade do |t|
    t.string "name"
    t.datetime "last_ran"
    t.bigint "location_id", null: false
    t.bigint "user_id"
    t.bigint "bay_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bay_id"], name: "index_inspections_on_bay_id"
    t.index ["location_id"], name: "index_inspections_on_location_id"
    t.index ["user_id"], name: "index_inspections_on_user_id"
  end

  create_table "inspections_equipments", force: :cascade do |t|
    t.bigint "inspection_id"
    t.bigint "equipment_id", null: false
    t.integer "status", default: 0, null: false
    t.text "description"
    t.text "reported_message"
    t.bigint "reported_by_id"
    t.datetime "reported_on"
    t.bigint "assigned_to_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "order", default: 0, null: false
    t.index ["assigned_to_id"], name: "index_inspections_equipments_on_assigned_to_id"
    t.index ["equipment_id"], name: "index_inspections_equipments_on_equipment_id"
    t.index ["inspection_id"], name: "index_inspections_equipments_on_inspection_id"
    t.index ["reported_by_id"], name: "index_inspections_equipments_on_reported_by_id"
  end

  create_table "invitation_events", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "event_id", null: false
    t.boolean "accepted", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_invitation_events_on_event_id"
    t.index ["user_id"], name: "index_invitation_events_on_user_id"
  end

  create_table "locations", force: :cascade do |t|
    t.string "name", null: false
    t.string "street_address"
    t.string "city"
    t.string "state"
    t.string "zipcode"
    t.string "timezone"
    t.string "email"
    t.string "phone"
    t.bigint "company_id", null: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "search"
    t.integer "order", default: 0, null: false
    t.index ["company_id"], name: "index_locations_on_company_id"
    t.index ["user_id"], name: "index_locations_on_user_id"
  end

  create_table "notes", force: :cascade do |t|
    t.text "content"
    t.string "noteable_type", null: false
    t.bigint "noteable_id", null: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["noteable_type", "noteable_id"], name: "index_notes_on_noteable"
    t.index ["user_id"], name: "index_notes_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "category", null: false
    t.string "code", null: false
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_notifications_on_code", unique: true
    t.index ["position"], name: "index_notifications_on_position", unique: true
  end

  create_table "recurring_events", force: :cascade do |t|
    t.string "title", null: false
    t.text "recurrence", null: false
    t.string "event_type", null: false
    t.datetime "due_date"
    t.string "sub_type"
    t.string "reminder"
    t.bigint "location_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_recurring_events_on_location_id"
    t.index ["user_id"], name: "index_recurring_events_on_user_id"
  end

  create_table "security_pins", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "pin_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_security_pins_on_user_id"
  end

  create_table "services", force: :cascade do |t|
    t.string "name"
    t.datetime "due_date"
    t.string "reminder"
    t.bigint "location_id", null: false
    t.bigint "user_id", null: false
    t.bigint "equipment_id"
    t.bigint "recurring_event_id"
    t.integer "status", default: 0, null: false
    t.bigint "assigned_to_id"
    t.bigint "completed_by_id"
    t.datetime "completed_on"
    t.bigint "skipped_by_id"
    t.datetime "skipped_on"
    t.text "search"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_to_id"], name: "index_services_on_assigned_to_id"
    t.index ["completed_by_id"], name: "index_services_on_completed_by_id"
    t.index ["equipment_id"], name: "index_services_on_equipment_id"
    t.index ["location_id"], name: "index_services_on_location_id"
    t.index ["recurring_event_id"], name: "index_services_on_recurring_event_id"
    t.index ["skipped_by_id"], name: "index_services_on_skipped_by_id"
    t.index ["user_id"], name: "index_services_on_user_id"
  end

  create_table "shift_breaks", force: :cascade do |t|
    t.bigint "shift_id", null: false
    t.string "name"
    t.time "start_time"
    t.time "end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shift_id"], name: "index_shift_breaks_on_shift_id"
  end

  create_table "shift_types", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "location_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position", default: 0, null: false
    t.time "start_time"
    t.time "end_time"
    t.index ["location_id"], name: "index_shift_types_on_location_id"
    t.index ["name", "location_id"], name: "index_shift_types_on_name_and_location_id", unique: true
  end

  create_table "task_lists", force: :cascade do |t|
    t.string "name"
    t.integer "order", null: false
    t.bigint "location_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_task_lists_on_location_id"
    t.index ["user_id"], name: "index_task_lists_on_user_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.text "description"
    t.bigint "user_id"
    t.bigint "location_id", null: false
    t.bigint "task_list_id"
    t.bigint "recurring_event_id"
    t.bigint "completed_by_id"
    t.datetime "completed_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "assigned_to_id"
    t.datetime "due_date"
    t.index ["assigned_to_id"], name: "index_tasks_on_assigned_to_id"
    t.index ["completed_by_id"], name: "index_tasks_on_completed_by_id"
    t.index ["location_id"], name: "index_tasks_on_location_id"
    t.index ["recurring_event_id"], name: "index_tasks_on_recurring_event_id"
    t.index ["task_list_id"], name: "index_tasks_on_task_list_id"
    t.index ["user_id"], name: "index_tasks_on_user_id"
  end

  create_table "user_locations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "location_id", null: false
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_user_locations_on_location_id"
    t.index ["user_id"], name: "index_user_locations_on_user_id"
  end

  create_table "user_notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "notification_id", null: false
    t.bigint "location_id", null: false
    t.boolean "email", default: true, null: false
    t.boolean "push_notification", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_user_notifications_on_location_id"
    t.index ["notification_id"], name: "index_user_notifications_on_notification_id"
    t.index ["user_id", "notification_id", "location_id"], name: "index_user_notifications_composite_key", unique: true
    t.index ["user_id"], name: "index_user_notifications_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "phone", null: false
    t.string "password_digest", null: false
    t.bigint "company_id", null: false
    t.date "last_login"
    t.string "reset_token"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "theme", default: "light", null: false
    t.integer "role"
    t.string "last_name"
    t.integer "week_start_day", default: 0, null: false
    t.integer "position", default: 0
    t.integer "creation_status", default: 0, null: false
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["last_name"], name: "index_users_on_last_name"
    t.index ["position"], name: "index_users_on_position"
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.json "object"
    t.json "object_changes"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "account_owners", "companies"
  add_foreign_key "account_owners", "users"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bays", "locations"
  add_foreign_key "bays", "users"
  add_foreign_key "employee_display_settings", "companies"
  add_foreign_key "employee_display_settings", "locations"
  add_foreign_key "equipment", "bays"
  add_foreign_key "equipment", "locations"
  add_foreign_key "equipment", "users"
  add_foreign_key "events", "locations"
  add_foreign_key "events", "shift_types"
  add_foreign_key "events", "users"
  add_foreign_key "events", "users", column: "reviewed_by_id"
  add_foreign_key "histories", "equipment"
  add_foreign_key "histories", "histories", column: "parent_id"
  add_foreign_key "histories", "users", column: "created_by_id"
  add_foreign_key "histories", "versions"
  add_foreign_key "incidents", "locations"
  add_foreign_key "incidents", "users"
  add_foreign_key "incidents", "users", column: "assigned_to_id"
  add_foreign_key "inspections", "bays"
  add_foreign_key "inspections", "locations"
  add_foreign_key "inspections", "users"
  add_foreign_key "inspections_equipments", "equipment"
  add_foreign_key "inspections_equipments", "inspections"
  add_foreign_key "inspections_equipments", "users", column: "assigned_to_id"
  add_foreign_key "inspections_equipments", "users", column: "reported_by_id"
  add_foreign_key "invitation_events", "events"
  add_foreign_key "invitation_events", "users"
  add_foreign_key "locations", "companies"
  add_foreign_key "locations", "users"
  add_foreign_key "notes", "users"
  add_foreign_key "recurring_events", "locations"
  add_foreign_key "recurring_events", "users"
  add_foreign_key "security_pins", "users"
  add_foreign_key "services", "equipment"
  add_foreign_key "services", "locations"
  add_foreign_key "services", "recurring_events"
  add_foreign_key "services", "users"
  add_foreign_key "services", "users", column: "assigned_to_id"
  add_foreign_key "services", "users", column: "completed_by_id"
  add_foreign_key "services", "users", column: "skipped_by_id"
  add_foreign_key "shift_breaks", "events", column: "shift_id"
  add_foreign_key "shift_types", "locations"
  add_foreign_key "task_lists", "locations"
  add_foreign_key "task_lists", "users"
  add_foreign_key "tasks", "locations"
  add_foreign_key "tasks", "recurring_events"
  add_foreign_key "tasks", "task_lists"
  add_foreign_key "tasks", "users"
  add_foreign_key "tasks", "users", column: "assigned_to_id"
  add_foreign_key "tasks", "users", column: "completed_by_id"
  add_foreign_key "user_locations", "locations"
  add_foreign_key "user_locations", "users"
  add_foreign_key "user_notifications", "locations"
  add_foreign_key "user_notifications", "notifications"
  add_foreign_key "user_notifications", "users"
  add_foreign_key "users", "companies"
end

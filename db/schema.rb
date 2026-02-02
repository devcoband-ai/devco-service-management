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

ActiveRecord::Schema[8.1].define(version: 2026_02_01_235218) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_requests", force: :cascade do |t|
    t.string "action_type"
    t.datetime "created_at", null: false
    t.jsonb "payload"
    t.datetime "requested_at"
    t.string "required_tier"
    t.text "resolution_notes"
    t.datetime "resolved_at"
    t.string "resolved_by"
    t.string "risk_level"
    t.string "status"
    t.datetime "updated_at", null: false
  end

  create_table "activity_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "event_type"
    t.text "intent"
    t.jsonb "metadata"
    t.text "metadata_json"
    t.datetime "occurred_at"
    t.string "source"
    t.bigint "source_id"
    t.string "source_type"
    t.integer "tier"
    t.datetime "updated_at", null: false
  end

  create_table "api_clients", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "api_token", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["api_token"], name: "index_api_clients_on_api_token", unique: true
  end

  create_table "articles", force: :cascade do |t|
    t.text "body_html"
    t.text "body_md"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename"
    t.string "status"
    t.string "subtitle"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "voice_id", null: false
    t.index ["voice_id"], name: "index_articles_on_voice_id"
  end

  create_table "book_renditions", force: :cascade do |t|
    t.string "cover_image_path"
    t.datetime "created_at", null: false
    t.string "file_path"
    t.string "format"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "version"
  end

  create_table "chat_messages", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}
    t.string "role", null: false
    t.string "session_id", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_chat_messages_on_created_at"
    t.index ["session_id"], name: "index_chat_messages_on_session_id"
  end

  create_table "credentials", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "last_rotated_at"
    t.string "location"
    t.string "name"
    t.text "notes"
    t.string "service"
    t.datetime "updated_at", null: false
  end

  create_table "decision_logs", force: :cascade do |t|
    t.text "consequences"
    t.text "context"
    t.datetime "created_at", null: false
    t.datetime "decided_at"
    t.text "decision"
    t.string "status", default: "active"
    t.text "tags"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "dimension_progresses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "max_score"
    t.string "name"
    t.text "notes"
    t.integer "score"
    t.datetime "updated_at", null: false
  end

  create_table "feature_flags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "enabled", default: true, null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["enabled"], name: "index_feature_flags_on_enabled"
    t.index ["name"], name: "index_feature_flags_on_name", unique: true
  end

  create_table "guardrails", force: :cascade do |t|
    t.boolean "active"
    t.string "category"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "enforcement_kind"
    t.string "name"
    t.text "rationale"
    t.text "rule"
    t.string "tier"
    t.datetime "updated_at", null: false
  end

  create_table "intel_feeds", force: :cascade do |t|
    t.boolean "active"
    t.jsonb "config"
    t.datetime "created_at", null: false
    t.string "feed_type"
    t.datetime "last_polled_at"
    t.string "name"
    t.integer "poll_interval_minutes"
    t.string "query"
    t.bigint "sentinel_id"
    t.string "source_url"
    t.datetime "updated_at", null: false
    t.index ["sentinel_id"], name: "index_intel_feeds_on_sentinel_id"
  end

  create_table "intel_items", force: :cascade do |t|
    t.string "author"
    t.text "content"
    t.datetime "created_at", null: false
    t.bigint "intel_feed_id", null: false
    t.jsonb "metadata"
    t.datetime "published_at"
    t.float "relevance_score"
    t.string "source_url"
    t.text "tags"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["intel_feed_id"], name: "index_intel_items_on_intel_feed_id"
  end

  create_table "learning_modules", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "number"
    t.date "scheduled_date"
    t.string "status"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "llm_assignments", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "assigned_at"
    t.bigint "assigned_by_id"
    t.string "capability", null: false
    t.datetime "created_at", null: false
    t.bigint "llm_model_id", null: false
    t.integer "max_requests_per_hour"
    t.integer "priority", default: 0, null: false
    t.bigint "role_id"
    t.datetime "updated_at", null: false
    t.index ["assigned_by_id"], name: "index_llm_assignments_on_assigned_by_id"
    t.index ["capability", "role_id", "priority"], name: "index_llm_assignments_on_capability_and_role_id_and_priority"
    t.index ["capability"], name: "index_llm_assignments_on_capability"
    t.index ["llm_model_id"], name: "index_llm_assignments_on_llm_model_id"
    t.index ["role_id"], name: "index_llm_assignments_on_role_id"
  end

  create_table "llm_models", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.jsonb "capabilities", default: []
    t.boolean "certified", default: false, null: false
    t.datetime "certified_at"
    t.bigint "certified_by_id"
    t.integer "context_window"
    t.decimal "cost_per_1k_input", precision: 10, scale: 6
    t.decimal "cost_per_1k_output", precision: 10, scale: 6
    t.datetime "created_at", null: false
    t.bigint "llm_provider_id", null: false
    t.integer "max_tokens"
    t.string "model_id", null: false
    t.string "name", null: false
    t.text "notes"
    t.integer "tier", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["certified_by_id"], name: "index_llm_models_on_certified_by_id"
    t.index ["llm_provider_id"], name: "index_llm_models_on_llm_provider_id"
    t.index ["model_id"], name: "index_llm_models_on_model_id"
    t.index ["tier"], name: "index_llm_models_on_tier"
  end

  create_table "llm_providers", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.text "api_key_encrypted"
    t.string "base_url"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.text "notes"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_llm_providers_on_slug", unique: true
  end

  create_table "milestones", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.text "description"
    t.date "target_date"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "patterns", force: :cascade do |t|
    t.string "also_known_as"
    t.bigint "article_id"
    t.text "consequences"
    t.text "context"
    t.datetime "created_at", null: false
    t.text "mechanics_markdown"
    t.string "name"
    t.integer "number"
    t.string "one_liner"
    t.text "problem"
    t.string "related_patterns"
    t.text "solution"
    t.text "tags"
    t.datetime "updated_at", null: false
    t.index ["article_id"], name: "index_patterns_on_article_id"
  end

  create_table "permissions", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.string "resource", null: false
    t.datetime "updated_at", null: false
    t.index ["resource", "action"], name: "index_permissions_on_resource_and_action", unique: true
  end

  create_table "posture_checks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "last_checked_at"
    t.string "name"
    t.text "notes"
    t.string "status"
    t.datetime "updated_at", null: false
  end

  create_table "role_permissions", force: :cascade do |t|
    t.jsonb "conditions", default: {}
    t.datetime "created_at", null: false
    t.bigint "permission_id", null: false
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.index ["permission_id"], name: "index_role_permissions_on_permission_id"
    t.index ["role_id", "permission_id"], name: "index_role_permissions_on_role_id_and_permission_id", unique: true
    t.index ["role_id"], name: "index_role_permissions_on_role_id"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.jsonb "permissions", default: {}, null: false
    t.boolean "system_role", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "security_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "event_type"
    t.datetime "occurred_at"
    t.string "severity"
    t.datetime "updated_at", null: false
  end

  create_table "sensitive_files", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "file_path"
    t.datetime "last_audited_at"
    t.string "risk_description"
    t.datetime "updated_at", null: false
  end

  create_table "sentinel_runs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "ended_at"
    t.text "error"
    t.integer "items_created", default: 0
    t.integer "items_found", default: 0
    t.bigint "sentinel_id", null: false
    t.datetime "started_at"
    t.string "status"
    t.text "summary"
    t.datetime "updated_at", null: false
    t.index ["sentinel_id"], name: "index_sentinel_runs_on_sentinel_id"
  end

  create_table "sentinels", force: :cascade do |t|
    t.jsonb "config"
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true
    t.string "kind"
    t.datetime "last_run_at"
    t.string "name", null: false
    t.string "schedule"
    t.jsonb "state_json"
    t.datetime "updated_at", null: false
  end

  create_table "sm_boards", force: :cascade do |t|
    t.jsonb "columns", default: []
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "project_id", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_sm_boards_on_project_id"
  end

  create_table "sm_comments", force: :cascade do |t|
    t.bigint "author_id"
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.bigint "issue_id", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_sm_comments_on_author_id"
    t.index ["issue_id"], name: "index_sm_comments_on_issue_id"
  end

  create_table "sm_issue_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "link_type", null: false
    t.bigint "source_issue_id", null: false
    t.bigint "target_issue_id", null: false
    t.index ["source_issue_id", "target_issue_id", "link_type"], name: "idx_sm_issue_links_unique", unique: true
    t.index ["source_issue_id"], name: "index_sm_issue_links_on_source_issue_id"
    t.index ["target_issue_id"], name: "index_sm_issue_links_on_target_issue_id"
  end

  create_table "sm_issues", force: :cascade do |t|
    t.bigint "assignee_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.date "due_date"
    t.string "file_path"
    t.string "issue_type", null: false
    t.jsonb "labels", default: []
    t.string "priority", default: "medium", null: false
    t.bigint "project_id", null: false
    t.bigint "reporter_id"
    t.string "sprint"
    t.string "status", default: "backlog", null: false
    t.integer "story_points"
    t.string "title", null: false
    t.string "tracking_id", null: false
    t.datetime "updated_at", null: false
    t.index ["assignee_id"], name: "index_sm_issues_on_assignee_id"
    t.index ["issue_type"], name: "index_sm_issues_on_issue_type"
    t.index ["priority"], name: "index_sm_issues_on_priority"
    t.index ["project_id"], name: "index_sm_issues_on_project_id"
    t.index ["reporter_id"], name: "index_sm_issues_on_reporter_id"
    t.index ["status"], name: "index_sm_issues_on_status"
    t.index ["tracking_id"], name: "index_sm_issues_on_tracking_id", unique: true
  end

  create_table "sm_projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.bigint "lead_id"
    t.string "name", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_sm_projects_on_key", unique: true
    t.index ["lead_id"], name: "index_sm_projects_on_lead_id"
  end

  create_table "sm_transitions", force: :cascade do |t|
    t.string "from_status", null: false
    t.bigint "issue_id", null: false
    t.string "to_status", null: false
    t.datetime "transitioned_at", null: false
    t.bigint "transitioned_by_id"
    t.index ["issue_id", "transitioned_at"], name: "index_sm_transitions_on_issue_id_and_transitioned_at"
    t.index ["issue_id"], name: "index_sm_transitions_on_issue_id"
    t.index ["transitioned_by_id"], name: "index_sm_transitions_on_transitioned_by_id"
  end

  create_table "user_roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "granted_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.bigint "granted_by_id"
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["granted_by_id"], name: "index_user_roles_on_granted_by_id"
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_user_roles_on_user_id_and_role_id", unique: true
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "voices", force: :cascade do |t|
    t.string "color_hex"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.string "slug"
    t.datetime "updated_at", null: false
  end

  create_table "webhook_deliveries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "delivered_at"
    t.string "event_type"
    t.text "payload"
    t.string "status"
    t.datetime "updated_at", null: false
    t.bigint "webhook_id", null: false
    t.index ["webhook_id"], name: "index_webhook_deliveries_on_webhook_id"
  end

  create_table "webhooks", force: :cascade do |t|
    t.boolean "active"
    t.datetime "created_at", null: false
    t.text "event_types"
    t.datetime "updated_at", null: false
    t.string "url"
  end

  create_table "work_products", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.text "description"
    t.jsonb "metadata"
    t.string "source_path"
    t.string "source_type"
    t.string "source_url"
    t.datetime "synced_at"
    t.text "tags"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "articles", "voices"
  add_foreign_key "intel_feeds", "sentinels"
  add_foreign_key "intel_items", "intel_feeds"
  add_foreign_key "llm_assignments", "llm_models"
  add_foreign_key "llm_assignments", "roles"
  add_foreign_key "llm_assignments", "users", column: "assigned_by_id"
  add_foreign_key "llm_models", "llm_providers"
  add_foreign_key "llm_models", "users", column: "certified_by_id"
  add_foreign_key "patterns", "articles"
  add_foreign_key "role_permissions", "permissions"
  add_foreign_key "role_permissions", "roles"
  add_foreign_key "sentinel_runs", "sentinels"
  add_foreign_key "sm_boards", "sm_projects", column: "project_id"
  add_foreign_key "sm_comments", "sm_issues", column: "issue_id"
  add_foreign_key "sm_comments", "users", column: "author_id"
  add_foreign_key "sm_issue_links", "sm_issues", column: "source_issue_id"
  add_foreign_key "sm_issue_links", "sm_issues", column: "target_issue_id"
  add_foreign_key "sm_issues", "sm_projects", column: "project_id"
  add_foreign_key "sm_issues", "users", column: "assignee_id"
  add_foreign_key "sm_issues", "users", column: "reporter_id"
  add_foreign_key "sm_projects", "users", column: "lead_id"
  add_foreign_key "sm_transitions", "sm_issues", column: "issue_id"
  add_foreign_key "sm_transitions", "users", column: "transitioned_by_id"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
  add_foreign_key "user_roles", "users", column: "granted_by_id"
  add_foreign_key "webhook_deliveries", "webhooks"
end

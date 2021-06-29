# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_08_21_212903) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bookmarks", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "user_type"
    t.string "document_id"
    t.string "document_type"
    t.binary "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id"], name: "index_bookmarks_on_document_id"
    t.index ["user_id"], name: "index_bookmarks_on_user_id"
  end

  create_table "checksum_audit_logs", force: :cascade do |t|
    t.string "file_set_id"
    t.string "file_id"
    t.string "checked_uri"
    t.string "expected_result"
    t.string "actual_result"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "passed"
    t.index ["checked_uri"], name: "index_checksum_audit_logs_on_checked_uri"
    t.index ["file_set_id", "file_id"], name: "by_file_set_id_and_file_id"
  end

  create_table "collection_branding_infos", force: :cascade do |t|
    t.string "collection_id"
    t.string "role"
    t.string "local_path"
    t.string "alt_text"
    t.string "target_url"
    t.integer "height"
    t.integer "width"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "collection_type_participants", force: :cascade do |t|
    t.bigint "hyrax_collection_type_id"
    t.string "agent_type"
    t.string "agent_id"
    t.string "access"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hyrax_collection_type_id"], name: "hyrax_collection_type_id"
  end

  create_table "content_blocks", force: :cascade do |t|
    t.string "name"
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_key"
  end

  create_table "curation_concerns_operations", force: :cascade do |t|
    t.string "status"
    t.string "operation_type"
    t.string "job_class"
    t.string "job_id"
    t.string "type"
    t.text "message"
    t.bigint "user_id"
    t.integer "parent_id"
    t.integer "lft", null: false
    t.integer "rgt", null: false
    t.integer "depth", default: 0, null: false
    t.integer "children_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lft"], name: "index_curation_concerns_operations_on_lft"
    t.index ["parent_id"], name: "index_curation_concerns_operations_on_parent_id"
    t.index ["rgt"], name: "index_curation_concerns_operations_on_rgt"
    t.index ["user_id"], name: "index_curation_concerns_operations_on_user_id"
  end

  create_table "featured_works", force: :cascade do |t|
    t.integer "order", default: 5
    t.string "work_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order"], name: "index_featured_works_on_order"
    t.index ["work_id"], name: "index_featured_works_on_work_id"
  end

  create_table "file_download_stats", force: :cascade do |t|
    t.datetime "date"
    t.integer "downloads"
    t.string "file_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["file_id"], name: "index_file_download_stats_on_file_id"
    t.index ["user_id"], name: "index_file_download_stats_on_user_id"
  end

  create_table "file_view_stats", force: :cascade do |t|
    t.datetime "date"
    t.integer "views"
    t.string "file_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["file_id"], name: "index_file_view_stats_on_file_id"
    t.index ["user_id"], name: "index_file_view_stats_on_user_id"
  end

  create_table "hyrax_collection_types", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.string "machine_id"
    t.boolean "nestable", default: true, null: false
    t.boolean "discoverable", default: true, null: false
    t.boolean "sharable", default: true, null: false
    t.boolean "allow_multiple_membership", default: true, null: false
    t.boolean "require_membership", default: false, null: false
    t.boolean "assigns_workflow", default: false, null: false
    t.boolean "assigns_visibility", default: false, null: false
    t.boolean "share_applies_to_new_works", default: true, null: false
    t.boolean "brandable", default: true, null: false
    t.string "badge_color", default: "#663333"
    t.index ["machine_id"], name: "index_hyrax_collection_types_on_machine_id", unique: true
  end

  create_table "hyrax_features", force: :cascade do |t|
    t.string "key", null: false
    t.boolean "enabled", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "job_io_wrappers", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "uploaded_file_id"
    t.string "file_set_id"
    t.string "mime_type"
    t.string "original_name"
    t.string "path"
    t.string "relation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uploaded_file_id"], name: "index_job_io_wrappers_on_uploaded_file_id"
    t.index ["user_id"], name: "index_job_io_wrappers_on_user_id"
  end

  create_table "mailboxer_conversation_opt_outs", id: :serial, force: :cascade do |t|
    t.string "unsubscriber_type"
    t.integer "unsubscriber_id"
    t.integer "conversation_id"
    t.index ["conversation_id"], name: "index_mailboxer_conversation_opt_outs_on_conversation_id"
    t.index ["unsubscriber_id", "unsubscriber_type"], name: "index_mailboxer_conversation_opt_outs_on_unsubscriber_id_type"
  end

  create_table "mailboxer_conversations", id: :serial, force: :cascade do |t|
    t.string "subject", default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mailboxer_notifications", id: :serial, force: :cascade do |t|
    t.string "type"
    t.text "body"
    t.string "subject", default: ""
    t.string "sender_type"
    t.integer "sender_id"
    t.integer "conversation_id"
    t.boolean "draft", default: false
    t.string "notification_code"
    t.string "notified_object_type"
    t.integer "notified_object_id"
    t.string "attachment"
    t.datetime "updated_at", null: false
    t.datetime "created_at", null: false
    t.boolean "global", default: false
    t.datetime "expires"
    t.index ["conversation_id"], name: "index_mailboxer_notifications_on_conversation_id"
    t.index ["notified_object_id", "notified_object_type"], name: "index_mailboxer_notifications_on_notified_object_id_and_type"
    t.index ["notified_object_type", "notified_object_id"], name: "mailboxer_notifications_notified_object"
    t.index ["sender_id", "sender_type"], name: "index_mailboxer_notifications_on_sender_id_and_sender_type"
    t.index ["type"], name: "index_mailboxer_notifications_on_type"
  end

  create_table "mailboxer_receipts", id: :serial, force: :cascade do |t|
    t.string "receiver_type"
    t.integer "receiver_id"
    t.integer "notification_id", null: false
    t.boolean "is_read", default: false
    t.boolean "trashed", default: false
    t.boolean "deleted", default: false
    t.string "mailbox_type", limit: 25
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_delivered", default: false
    t.string "delivery_method"
    t.string "message_id"
    t.index ["notification_id"], name: "index_mailboxer_receipts_on_notification_id"
    t.index ["receiver_id", "receiver_type"], name: "index_mailboxer_receipts_on_receiver_id_and_receiver_type"
  end

  create_table "minter_states", id: :serial, force: :cascade do |t|
    t.string "namespace", default: "default", null: false
    t.string "template", null: false
    t.text "counters"
    t.bigint "seq", default: 0
    t.binary "rand"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["namespace"], name: "index_minter_states_on_namespace", unique: true
  end

  create_table "permission_template_accesses", force: :cascade do |t|
    t.bigint "permission_template_id"
    t.string "agent_type"
    t.string "agent_id"
    t.string "access"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["permission_template_id", "agent_id", "agent_type", "access"], name: "uk_permission_template_accesses", unique: true
    t.index ["permission_template_id"], name: "index_permission_template_accesses_on_permission_template_id"
  end

  create_table "permission_templates", force: :cascade do |t|
    t.string "source_id"
    t.string "visibility"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "release_date"
    t.string "release_period"
    t.index ["source_id"], name: "index_permission_templates_on_source_id", unique: true
  end

  create_table "proxy_deposit_requests", force: :cascade do |t|
    t.string "work_id", null: false
    t.bigint "sending_user_id", null: false
    t.bigint "receiving_user_id", null: false
    t.datetime "fulfillment_date"
    t.string "status", default: "pending", null: false
    t.text "sender_comment"
    t.text "receiver_comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["receiving_user_id"], name: "index_proxy_deposit_requests_on_receiving_user_id"
    t.index ["sending_user_id"], name: "index_proxy_deposit_requests_on_sending_user_id"
  end

  create_table "proxy_deposit_rights", force: :cascade do |t|
    t.bigint "grantor_id"
    t.bigint "grantee_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["grantee_id"], name: "index_proxy_deposit_rights_on_grantee_id"
    t.index ["grantor_id"], name: "index_proxy_deposit_rights_on_grantor_id"
  end

  create_table "qa_local_authorities", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_qa_local_authorities_on_name", unique: true
  end

  create_table "qa_local_authority_entries", force: :cascade do |t|
    t.bigint "local_authority_id"
    t.string "label"
    t.string "uri"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["local_authority_id"], name: "index_qa_local_authority_entries_on_local_authority_id"
    t.index ["uri"], name: "index_qa_local_authority_entries_on_uri", unique: true
  end

  create_table "searches", id: :serial, force: :cascade do |t|
    t.binary "query_params"
    t.integer "user_id"
    t.string "user_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_searches_on_user_id"
  end

  create_table "single_use_links", force: :cascade do |t|
    t.string "downloadKey"
    t.string "path"
    t.string "itemId"
    t.datetime "expires"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sipity_agents", force: :cascade do |t|
    t.string "proxy_for_id", null: false
    t.string "proxy_for_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["proxy_for_id", "proxy_for_type"], name: "sipity_agents_proxy_for", unique: true
  end

  create_table "sipity_comments", force: :cascade do |t|
    t.integer "entity_id", null: false
    t.integer "agent_id", null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_id"], name: "index_sipity_comments_on_agent_id"
    t.index ["created_at"], name: "index_sipity_comments_on_created_at"
    t.index ["entity_id"], name: "index_sipity_comments_on_entity_id"
  end

  create_table "sipity_entities", force: :cascade do |t|
    t.string "proxy_for_global_id", null: false
    t.integer "workflow_id", null: false
    t.integer "workflow_state_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["proxy_for_global_id"], name: "sipity_entities_proxy_for_global_id", unique: true
    t.index ["workflow_id"], name: "index_sipity_entities_on_workflow_id"
    t.index ["workflow_state_id"], name: "index_sipity_entities_on_workflow_state_id"
  end

  create_table "sipity_entity_specific_responsibilities", force: :cascade do |t|
    t.integer "workflow_role_id", null: false
    t.string "entity_id", null: false
    t.integer "agent_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_id"], name: "sipity_entity_specific_responsibilities_agent"
    t.index ["entity_id"], name: "sipity_entity_specific_responsibilities_entity"
    t.index ["workflow_role_id", "entity_id", "agent_id"], name: "sipity_entity_specific_responsibilities_aggregate", unique: true
    t.index ["workflow_role_id"], name: "sipity_entity_specific_responsibilities_role"
  end

  create_table "sipity_notifiable_contexts", force: :cascade do |t|
    t.integer "scope_for_notification_id", null: false
    t.string "scope_for_notification_type", null: false
    t.string "reason_for_notification", null: false
    t.integer "notification_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notification_id"], name: "sipity_notifiable_contexts_notification_id"
    t.index ["scope_for_notification_id", "scope_for_notification_type", "reason_for_notification", "notification_id"], name: "sipity_notifiable_contexts_concern_surrogate", unique: true
    t.index ["scope_for_notification_id", "scope_for_notification_type", "reason_for_notification"], name: "sipity_notifiable_contexts_concern_context"
    t.index ["scope_for_notification_id", "scope_for_notification_type"], name: "sipity_notifiable_contexts_concern"
  end

  create_table "sipity_notification_recipients", force: :cascade do |t|
    t.integer "notification_id", null: false
    t.integer "role_id", null: false
    t.string "recipient_strategy", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notification_id", "role_id", "recipient_strategy"], name: "sipity_notifications_recipients_surrogate"
    t.index ["notification_id"], name: "sipity_notification_recipients_notification"
    t.index ["recipient_strategy"], name: "sipity_notification_recipients_recipient_strategy"
    t.index ["role_id"], name: "sipity_notification_recipients_role"
  end

  create_table "sipity_notifications", force: :cascade do |t|
    t.string "name", null: false
    t.string "notification_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_sipity_notifications_on_name", unique: true
    t.index ["notification_type"], name: "index_sipity_notifications_on_notification_type"
  end

  create_table "sipity_roles", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_sipity_roles_on_name", unique: true
  end

  create_table "sipity_workflow_actions", force: :cascade do |t|
    t.integer "workflow_id", null: false
    t.integer "resulting_workflow_state_id"
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["resulting_workflow_state_id"], name: "sipity_workflow_actions_resulting_workflow_state"
    t.index ["workflow_id", "name"], name: "sipity_workflow_actions_aggregate", unique: true
    t.index ["workflow_id"], name: "sipity_workflow_actions_workflow"
  end

  create_table "sipity_workflow_methods", force: :cascade do |t|
    t.string "service_name", null: false
    t.integer "weight", null: false
    t.integer "workflow_action_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workflow_action_id"], name: "index_sipity_workflow_methods_on_workflow_action_id"
  end

  create_table "sipity_workflow_responsibilities", force: :cascade do |t|
    t.integer "agent_id", null: false
    t.integer "workflow_role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_id", "workflow_role_id"], name: "sipity_workflow_responsibilities_aggregate", unique: true
  end

  create_table "sipity_workflow_roles", force: :cascade do |t|
    t.integer "workflow_id", null: false
    t.integer "role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workflow_id", "role_id"], name: "sipity_workflow_roles_aggregate", unique: true
  end

  create_table "sipity_workflow_state_action_permissions", force: :cascade do |t|
    t.integer "workflow_role_id", null: false
    t.integer "workflow_state_action_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workflow_role_id", "workflow_state_action_id"], name: "sipity_workflow_state_action_permissions_aggregate", unique: true
  end

  create_table "sipity_workflow_state_actions", force: :cascade do |t|
    t.integer "originating_workflow_state_id", null: false
    t.integer "workflow_action_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["originating_workflow_state_id", "workflow_action_id"], name: "sipity_workflow_state_actions_aggregate", unique: true
  end

  create_table "sipity_workflow_states", force: :cascade do |t|
    t.integer "workflow_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_sipity_workflow_states_on_name"
    t.index ["workflow_id", "name"], name: "sipity_type_state_aggregate", unique: true
  end

  create_table "sipity_workflows", force: :cascade do |t|
    t.string "name", null: false
    t.string "label"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "permission_template_id"
    t.boolean "active"
    t.boolean "allows_access_grant"
    t.index ["permission_template_id", "name"], name: "index_sipity_workflows_on_permission_template_and_name", unique: true
  end

  create_table "tinymce_assets", force: :cascade do |t|
    t.string "file"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "trophies", force: :cascade do |t|
    t.integer "user_id"
    t.string "work_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "uploaded_files", force: :cascade do |t|
    t.string "file"
    t.bigint "user_id"
    t.string "file_set_uri"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["file_set_uri"], name: "index_uploaded_files_on_file_set_uri"
    t.index ["user_id"], name: "index_uploaded_files_on_user_id"
  end

  create_table "user_stats", force: :cascade do |t|
    t.integer "user_id"
    t.datetime "date"
    t.integer "file_views"
    t.integer "file_downloads"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "work_views"
    t.index ["user_id"], name: "index_user_stats_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "guest", default: false
    t.string "facebook_handle"
    t.string "twitter_handle"
    t.string "googleplus_handle"
    t.string "display_name"
    t.string "address"
    t.string "admin_area"
    t.string "department"
    t.string "title"
    t.string "office"
    t.string "chat_id"
    t.string "website"
    t.string "affiliation"
    t.string "telephone"
    t.string "avatar_file_name"
    t.string "avatar_content_type"
    t.integer "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.string "linkedin_handle"
    t.string "orcid"
    t.string "arkivo_token"
    t.string "arkivo_subscription"
    t.binary "zotero_token"
    t.string "zotero_userid"
    t.string "preferred_locale"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "version_committers", force: :cascade do |t|
    t.string "obj_id"
    t.string "datastream_id"
    t.string "version_id"
    t.string "committer_login"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "work_view_stats", force: :cascade do |t|
    t.datetime "date"
    t.integer "work_views"
    t.string "work_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["user_id"], name: "index_work_view_stats_on_user_id"
    t.index ["work_id"], name: "index_work_view_stats_on_work_id"
  end

  add_foreign_key "collection_type_participants", "hyrax_collection_types"
  add_foreign_key "curation_concerns_operations", "users"
  add_foreign_key "mailboxer_conversation_opt_outs", "mailboxer_conversations", column: "conversation_id", name: "mb_opt_outs_on_conversations_id"
  add_foreign_key "mailboxer_notifications", "mailboxer_conversations", column: "conversation_id", name: "notifications_on_conversation_id"
  add_foreign_key "mailboxer_receipts", "mailboxer_notifications", column: "notification_id", name: "receipts_on_notification_id"
  add_foreign_key "permission_template_accesses", "permission_templates"
  add_foreign_key "qa_local_authority_entries", "qa_local_authorities", column: "local_authority_id"
  add_foreign_key "uploaded_files", "users"
end

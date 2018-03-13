ActiveRecord::Schema.define(version: 20180310142108) do

  create_table "push_notifications" do |t|
    t.integer "topic", limit: 1, null: false
    t.string "subject"
    t.text "message"
    t.text "message_options_json", null: false
    t.datetime "sent_at"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_push_notifications_on_user_id"
  end

  create_table "topic_push_notifications" do |t|
    t.integer "topic", limit: 1, null: false
    t.string "subject"
    t.text "message"
    t.text "message_options_json", null: false
    t.datetime "send_at", null: false
    t.datetime "sent_at"
    t.boolean "published", default: false, null: false
  end

  create_table "user_push_notification_settings" do |t|
    t.bigint "user_id", null: false
    t.boolean "topic1_enabled", default: true, null: false
    t.index ["user_id"], name: "index_user_push_notification_settings_on_user_id", unique: true
  end

  create_table "user_push_notification_tokens" do |t|
    t.bigint "user_id", null: false
    t.integer "mobile_platform", limit: 1, null: false
    t.string "device_token", null: false
    t.string "endpoint_arn", null: false
    t.string "topic1_subscription_arn", null: false
    t.index ["user_id", "mobile_platform"], name: "user_platforum_index", unique: true
  end

end

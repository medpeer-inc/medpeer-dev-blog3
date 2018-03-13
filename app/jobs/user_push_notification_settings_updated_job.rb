class UserPushNotificationSettingsUpdatedJob < ApplicationJob
  def perform(user_id:)
    user = User.find user_id
    push_notification_service = PushNotificationBlogSample.new
    
    # エラー発生時、デフォルトだとsidekiqは再実行してしまうので適宜エラー処理を追加して下さい
    push_notification_service.on_updated_setting(user)
    end
  end
end

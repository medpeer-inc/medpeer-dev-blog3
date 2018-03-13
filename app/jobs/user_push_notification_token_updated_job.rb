class UserPushNotificationTokenUpdatedJob < ApplicationJob
  def perform(user_push_notification_token_id:)
    user_push_notification_token = UserPushNotificationToken.find user_push_notification_token_id
    push_notification_service = PushNotificationBlogSample.new

    # エラー発生時、デフォルトだとsidekiqは再実行してしまうので適宜エラー処理を追加して下さい
    push_notification_service.on_updated_token(user_push_notification_token)
  end
end

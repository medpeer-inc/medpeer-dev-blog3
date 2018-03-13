# ブログのサンプルコードが書かれているファイルです
class PushNotificationBlogSample
  def on_updated_token(user_push_notification_token)

    has_device_token = user_push_notification_token.device_token.present?
    has_endpoint_arn = user_push_notification_token.endpoint_arn.present?

    if has_endpoint_arn
      if has_device_token
        set_endpoint_attributes(user_push_notification_token)
      else
        delete_endpoint(user_push_notification_token) 
        # https://docs.aws.amazon.com/ja_jp/sns/latest/api/API_DeleteEndpoint.html
        # > When you delete an endpoint that is also subscribed to a topic,
        # then you must also unsubscribe the endpoint from the topic
        unsubscribe_all_topics([user_push_notification_token])
      end
    else
      return unless has_device_token
      create_platform_endpoint(user_push_notification_token)
      on_updated_setting(user_push_notification_token.user)
    end
  end

  def on_updated_setting(user)
    user_push_notification_setting = user.user_push_notification_setting
    UserPushNotificationSetting::SUBSCRIBE_TOPICS.each do |topic|
      if user_push_notification_setting.enabled_by(topic)
        subscribe_topics(topic, user.user_push_notification_tokens)
      else
        unsubscribe_topics(topic, user.user_push_notification_tokens)
      end
    end
  end

  def publish_to_topic(topic_push_notification)
    return unless topic_push_notification.sendable?
    requester = AwsSnsRequester.new
    topic_push_notification.send_notification
    requester.publish_to_topic(topic_name: topic_push_notification.topic.to_sym,
                               subject: topic_push_notification.subject,
                               message: topic_push_notification.message,
                               message_options: topic_push_notification.message_options)
    topic_push_notification.with_writable { topic_push_notification.save! }
  end

  def publish_to_user(push_notification)
    return if push_notification.sent?
    to_user = push_notification.user
    return unless to_user.app_logged_in?
    return unless to_user.user_push_notification_setting.enabled_by(push_notification.topic)

    # 全デバイス分送信
    requester = AwsSnsRequester.new
    to_user.user_push_notification_tokens.each do |token|
      next unless token.enable_publish?
      push_notification.send_notification
      begin
        requester.publish_to_endpoint(endpoint_arn: token.endpoint_arn, message: push_notification.message,
                                      message_options: push_notification.message_options_with_analytics_values,
                                      subject: push_notification.subject, badge: push_notification.badge_count)
        push_notification.with_writable { push_notification.save! }
      rescue Aws::SNS::Errors::EndpointDisabled
        # ユーザーへのPush通知が届かず、Amazon SNS側でEndpointがDisable状態になっている時に
        # publishを行うと発生します。endpointを削除するなど、適宜実装して下さい。
      end
    end
  end

  private

  def delete_endpoint(user_push_notification_token)
    requester = AwsSnsRequester.new
    requester.delete_endpoint(user_push_notification_token.endpoint_arn)
    user_push_notification_token.endpoint_arn = ""
    user_push_notification_token.with_writable { user_push_notification_token.save }
  end

  def set_endpoint_attributes(user_push_notification_token)
    requester = AwsSnsRequester.new
    requester.set_endpoint_attributes(user_push_notification_token.endpoint_arn,
                                      user_push_notification_token.device_token)
  end

  def create_platform_endpoint(user_push_notification_token)
    requester = AwsSnsRequester.new
    response = requester.create_platform_endpoint(user_push_notification_token.user_id,
                                                  user_push_notification_token.device_token,
                                                  user_push_notification_token.mobile_platform.value)
    user_push_notification_token.endpoint_arn = response.endpoint_arn
    user_push_notification_token.with_writable { user_push_notification_token.save }
  end

  def subscribe_topics(topic, user_push_notification_tokens)
    log_params = { user_push_notification_tokens: user_push_notification_tokens.map(&:id) }
    user_push_notification_tokens.each do |token|
      next unless token.enable_subscribe? topic
      response = requester.subscribe(topic, token.endpoint_arn)
      token.set_subscription_arn_by(topic, response.subscription_arn)
      token.save
    end
  end

  def unsubscribe_all_topics(user_push_notification_tokens)
    UserPushNotificationSetting::SUBSCRIBE_TOPICS.each do |topic|
      unsubscribe_topics(topic, user_push_notification_tokens)
    end
  end

  def unsubscribe_topics(topic, user_push_notification_tokens)
    requester = AwsSnsRequester.new
    user_push_notification_tokens.each do |token|
      next unless token.enable_unsubscribe? topic
      requester.unsubscribe(token.subscription_arn_by(topic))
      token.set_subscription_arn_by(topic, "")
      token.save
    end
  end
end

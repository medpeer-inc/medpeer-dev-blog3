# AWS SNSのリクエストラッパークラス
# http://docs.aws.amazon.com/sdkforruby/api/Aws/SNS/Client.html
class AwsSnsRequester
  def create_platform_endpoint(user_id, token, mobile_platform)
    client.create_platform_endpoint(platform_application_arn: config[:platform_application_arn][mobile_platform],
                                    token: token, custom_user_data: custom_user_data(user_id, mobile_platform))
  end

  def delete_endpoint(endpoint_arn)
    client.delete_endpoint(endpoint_arn: endpoint_arn)
  end

  def set_endpoint_attributes(endpoint_arn, device_token)
    attributes = { "Enabled" => "true", "Token" => device_token }
    client.set_endpoint_attributes(endpoint_arn: endpoint_arn, attributes: attributes)
  end

  def subscribe(topic_name, endpoint_arn)
    topic_arn = config[:topics][topic_name]
    client.subscribe(topic_arn: topic_arn, protocol: "application", endpoint: endpoint_arn)
  end

  def unsubscribe(subscription_arn)
    client.unsubscribe(subscription_arn: subscription_arn)
  end

  def publish_to_endpoint(endpoint_arn:, subject:, message:, message_options:, badge:)
    client.publish(target_arn: endpoint_arn, subject: subject,
                   message: structured_message(message: message, message_options: message_options, badge: badge),
                   message_structure: :json)
  end

  def publish_to_topic(topic_name:, subject:, message:, message_options:)
    topic_arn = config[:topics][topic_name]
    client.publish(topic_arn: topic_arn,
                   message: structured_message(message: message, message_options: message_options),
                   subject: subject, message_structure: :json)
  end

  private

  def structured_message(message:, message_options:, badge: nil)
    aps = { aps: { alert: message, sound: 'default' } }
    aps[:aps][:badge] = badge if badge
    aps.merge! message_options
    { default: message, APNS: aps.to_json, APNS_SANDBOX: aps.to_json }.to_json
  end

  def client
    @client ||= Aws::SNS::Client.new(access_key_id: config[:access_key_id],
                                     secret_access_key: config[:secret_access_key],
                                     region: config[:region])
  end

  def config
    @config ||= Rails.application.secrets.mobile_app[:aws_sns]
  end

  def custom_user_data(user_id, mobile_platform)
    @custom_user_data ||= { user_id: user_id, mobile_platform: mobile_platform }.to_json
  end
end

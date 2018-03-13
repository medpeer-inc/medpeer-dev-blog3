class MobileApp::Api::UserPushNotificationTokensController < MobileApp::Api::ApplicationController
  def update
    user_push_notification_token.device_token = permited_params[:token]
    unless user_push_notification_token.changed?
      render json: user_push_notification_token
      return
    end

    if UserPushNotificationToken.with_writable { user_push_notification_token.save }
      job_params = { user_push_notification_token_id: user_push_notification_token.id }
      UserPushNotificationTokenUpdatedJob.perform_later(job_params)
      render json: user_push_notification_token
    else
      render_error MobileApp::Error.validation_error(user_push_notification_token.errors)
    end
  end

  private

  def user_push_notification_token
    # TODO: ios/androidで切り替え
    platform = UserPushNotificationToken.mobile_platform.ios
    @user_push_notification_token ||=
      begin
        UserPushNotificationToken.with_writable do
          current_user.user_push_notification_tokens.with_mobile_platform(platform).first_or_create!
        end
      rescue ActiveRecord::RecordNotUnique
        current_user.user_push_notification_tokens.with_mobile_platform(platform).take!
      end
  end

  def permited_params
    params.permit(:token)
  end
end

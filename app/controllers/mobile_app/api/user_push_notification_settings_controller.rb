class MobileApp::Api::UserPushNotificationSettingsController < MobileApp::Api::ApplicationController
  def show
    render json: current_user.user_push_notification_setting
  end

  def update
    user_push_notification_setting = current_user.user_push_notification_setting
    user_push_notification_setting.topic1_enabled = permited_params[:topic1_enabled]

    unless user_push_notification_setting.changed?
      render json: user_push_notification_setting
      return
    end

    if UserPushNotificationSetting.with_writable { user_push_notification_setting.save }
      UserPushNotificationSettingsUpdatedJob.perform_later(user_id: current_user.id)
      render json: user_push_notification_setting
    else
      render_error MobileApp::Error.validation_error(user_push_notification_setting.errors)
    end
  end

  private

  def permited_params
    params.permit(:topic1_enabled)
  end
end

Rails.application.routes.draw do
  namespace :mobile_app, path: '/', format: false do
    resource :user_push_notification_setting, only: %i(show update)
    resource :user_push_notification_token, only: %i(update)
  end
end

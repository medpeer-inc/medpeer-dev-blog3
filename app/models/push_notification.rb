class PushNotification < ApplicationRecord
  belongs_to :user

  def badge_count
    # push通知でバッジ数をおくる時にはここで制御
  end

  def send_notification
    self.sent_at = Time.current
  end

  def sent?
    !sent_at.nil?
  end
end

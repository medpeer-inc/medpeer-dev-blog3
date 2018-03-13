class TopicPushNotification < ApplicationRecord
  def send_notification
    self.sent_at = Time.current
  end

  def sent?
    !sent_at.nil?
  end

  def send_at_passed?
    send_at <= Time.current
  end

  def sendable?
    !sent? && send_at_passed? && published
  end
end

class UserMailer < ActionMailer::Base
  default from: "do_not_reply@example.com"

  def new_follower_notification(user, follower)
    @user = user
    @follower = follower
    mail(:to => "#{user.email}",
         :subject => "@#{follower.username} is now following you!")
  end
end

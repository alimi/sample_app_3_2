namespace :db do
  desc "Add user_preference to existing users who do not have one"
  task add_user_preference_to_users: :environment do
    users_to_update = User.where("id not in (?)",
      UserPreference.select("user_id").map(&:user_id))
    users_to_update.each do |user|
      user.create_user_preference!(receive_follower_notification: true)
    end
  end
end

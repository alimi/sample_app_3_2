class UserPreference < ActiveRecord::Base
  attr_accessible :receive_follower_notification
  belongs_to :user
end

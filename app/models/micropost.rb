class Micropost < ActiveRecord::Base
  attr_accessible :content
  belongs_to :user
  belongs_to :in_reply_to_user, class_name: "User"

  validates :content, presence: true, length: { maximum: 140 }
  validates :user_id, presence: true

  before_save do |record|
    record.content.match(/^d@(\S+)/) do |match|
      record.direct_message = true
    end

    record.content.match(/^d?@(\S+)/) do |match|
      record.in_reply_to_user = User.find_by_username(match[1])
    end
  end

  default_scope order: 'microposts.created_at DESC'

  # Returns microposts from the users being followed by the given user.
  scope :from_users_followed_by, lambda { |user| followed_by(user) }

  scope :in_reply_to, lambda { |user| where("in_reply_to_user_id = ?", user) }
  scope :from_users_followed_by_and_in_reply_to_and_direct_message,
   lambda{ |user| followed_by_or_in_reply_to_or_direct_message(user) }
  scope :direct_message_to,
    lambda { |user|
      where("in_reply_to_user_id = ? AND direct_message = 't'", user) }
  scope :public_microposts_for,
    lambda { |user| where("user_id = ? AND direct_message is null", user) }

  private

  # Returns an SQL condition for users followed by the given user.
  # We include the user's own id as well.
  def self.followed_by(user)
    followed_user_ids =  %(SELECT followed_id FROM relationships
                           WHERE follower_id = :user_id)
    where("user_id IN (#{followed_user_ids}) OR user_id = :user_id",
          { user_id: user })
  end

  def self.followed_by_or_in_reply_to_or_direct_message(user)
    followed_user_ids =  %(SELECT followed_id FROM relationships
                           WHERE follower_id = :user_id)
    where(%((user_id IN (#{followed_user_ids}) AND direct_message is null) OR
            user_id = :user_id OR
            in_reply_to_user_id = :user_id),
          { user_id: user })
  end
end

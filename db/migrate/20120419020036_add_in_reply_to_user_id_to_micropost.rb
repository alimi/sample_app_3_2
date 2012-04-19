class AddInReplyToUserIdToMicropost < ActiveRecord::Migration
  def change
    add_column :microposts, :in_reply_to_user_id, :integer
    add_index :microposts, :in_reply_to_user_id
  end
end

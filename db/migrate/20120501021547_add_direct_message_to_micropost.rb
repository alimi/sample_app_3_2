class AddDirectMessageToMicropost < ActiveRecord::Migration
  def change
    add_column :microposts, :direct_message, :boolean
    add_index :microposts, :direct_message
  end
end

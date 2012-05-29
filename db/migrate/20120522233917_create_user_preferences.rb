class CreateUserPreferences < ActiveRecord::Migration
  def change
    create_table :user_preferences do |t|
      t.integer :user_id
      t.boolean :receive_follower_notification, :default => true

      t.timestamps
    end
    add_index :user_preferences, :user_id, unique: true
  end
end

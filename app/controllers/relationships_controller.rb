class RelationshipsController < ApplicationController
  before_filter :signed_in_user

  respond_to :html, :js

  def create
    @user = User.find(params[:relationship][:followed_id])
    current_user.follow!(@user)

    if @user.receive_follower_notification?
      UserMailer.new_follower_notification(@user, current_user).deliver
    end

    respond_with @user
  end

  def destroy
    @user = Relationship.find(params[:id]).followed
    current_user.unfollow!(@user)
    respond_with @user
  end
end

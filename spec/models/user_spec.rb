# == Schema Information
#
# Table name: users
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  email      :string(255)
#  created_at :datetime        not null
#  updated_at :datetime        not null
#

require 'spec_helper'

describe User do
  before do
    @user = User.new(name: "Example User", email: "user@example.com",
                     username: "example", password: "foobar", 
                     password_confirmation: "foobar")
  end

  subject { @user }

  it { should respond_to(:name) }
  it { should respond_to(:email) }
  it { should respond_to(:username) }
  it { should respond_to(:password_digest) }
  it { should respond_to(:password) }
  it { should respond_to(:password_confirmation) }
  it { should respond_to(:remember_token) }
  it { should respond_to(:admin) }
  it { should respond_to(:authenticate) }
  it { should respond_to(:authenticate) }
  it { should respond_to(:microposts) }
  it { should respond_to(:public_microposts) }
  it { should respond_to(:in_reply_to_microposts) }
  it { should respond_to(:feed) }
  it { should respond_to(:relationships) }
  it { should respond_to(:followed_users) }
  it { should respond_to(:reverse_relationships) }
  it { should respond_to(:followers) }
  it { should respond_to(:following?) }
  it { should respond_to(:follow!) }
  it { should respond_to(:unfollow!) }
  it { should respond_to(:receive_follower_notification?) }

  it { should be_valid }
  it { should_not be_admin }

  describe "with admin attribute set to 'true'" do
    before { @user.toggle!(:admin) }
    it { should be_admin }
  end

  describe "when name is not present" do
    before { @user.name = " " }
    it { should_not be_valid }
  end

  describe "when email is not present" do
    before { @user.email = " " }
    it { should_not be_valid }
  end

  describe "when name is too long" do
    before { @user.name = "a" * 51 }
    it { should_not be_valid }
  end
  
  describe "when email format is invalid" do
    invalid_addresses =  %w[user@foo,com user_at_foo.org example.user@foo.]
    invalid_addresses.each do |invalid_address|
      before { @user.email = invalid_address }
      it { should_not be_valid }
    end
  end

  describe "when email format is valid" do
    valid_addresses = %w[user@foo.com A_USER@f.b.org frst.lst@foo.jp a+b@baz.cn]
    valid_addresses.each do |valid_address|
      before { @user.email = valid_address }
      it { should be_valid }
    end
  end

  describe "when email address is already taken" do
    before do
      user_with_same_email = @user.dup
      user_with_same_email.email = @user.email.upcase
      user_with_same_email.save
    end

    it { should_not be_valid }
  end

  describe "when username is not present" do
    before { @user.username = "" }
    it { should_not be_valid }
  end

  describe "when username includes blank character" do
    before { @user.username = "user name" }
    it { should_not be_valid }
  end

  describe "when username is already taken" do
    before do
      other_user = @user.dup
      other_user.email = "duplicate@example.com"
      other_user.save
    end
    it { should_not be_valid }
  end

  describe "when password is not present" do
    before { @user.password = @user.password_confirmation = " " }
    it { should_not be_valid }
  end

  describe "when password doesn't match confirmation" do
    before { @user.password_confirmation = "mismatch" }
    it { should_not be_valid }
  end

  describe "with a password that's too short" do
    before { @user.password = @user.password_confirmation = "a" * 5 }
    it { should be_invalid }
  end

  describe "retun value of authenticate method" do
    before { @user.save }
    let(:found_user) { User.find_by_email(@user.email) }

    describe "with valid password" do
      it { should == found_user.authenticate(@user.password) }
    end

    describe "with invalid password" do
      let(:user_for_invalid_password) { found_user.authenticate("invalid") }

      it { should_not == user_for_invalid_password }
      specify { user_for_invalid_password.should be_false }
    end
  end

  describe "remember token" do
    before { @user.save }
    its(:remember_token) { should_not be_blank }
  end

  describe "micropost assocations" do
    before { @user.save }
    let!(:older_micropost) do
      FactoryGirl.create(:micropost, user: @user, created_at: 1.day.ago)
    end
    let!(:newer_micropost) do
      FactoryGirl.create(:micropost, user: @user, created_at: 1.hour.ago)
    end

    it "should have the right microposts in the right order" do
      @user.microposts.should == [newer_micropost, older_micropost]
    end

    it "should destroy associated microposts" do
      microposts = @user.microposts
      @user.destroy
      microposts.each do |micropost|
        Micropost.find_by_id(micropost.id).should be_nil
      end
    end

    describe "status" do
      let(:unfollowed_post) do
        FactoryGirl.create(:micropost, user: FactoryGirl.create(:user))
      end
      let(:followed_user) { FactoryGirl.create(:user) }
      let(:replying_user) { FactoryGirl.create(:user) }
      let(:dm_user) { FactoryGirl.create(:user) }
      let!(:replying_user_micropost) do 
        FactoryGirl.create(:micropost, user: replying_user, 
                           content: "@#{@user.username} content")
      end
      let!(:dm_user_micropost) do 
        FactoryGirl.create(:micropost, user: dm_user, 
                           content: "d@#{@user.username} content")
      end
      let!(:followed_user_dm_micropost) do 
        FactoryGirl.create(:micropost, user: followed_user, 
                           content: "d@#{dm_user.username} content")
      end

      before do
        @user.follow!(followed_user)
        3.times { followed_user.microposts.create!(content: "Lorem ipsum") }
      end

      its(:feed) { should include(newer_micropost) }
      its(:feed) { should include(older_micropost) }
      its(:feed) { should_not include(unfollowed_post) }
      its(:feed) do
        followed_user_microposts = followed_user.microposts.select do |post|
          !post.direct_message
        end
        followed_user_microposts.each do |micropost|
          should include(micropost)
        end
      end
      its(:feed) { should include(replying_user_micropost) }
      its(:feed) { should include(dm_user_micropost) }
      its(:feed) { should_not include(followed_user_dm_micropost) }
    end
  end

  describe "public microposts" do
    before { @user.save }

    let(:other_user) { FactoryGirl.create(:user) }
    let(:public_micropost) { FactoryGirl.create(:micropost, user: @user) } 
    let(:private_micropost) do
      FactoryGirl.create(:micropost, user: @user,
        content: "d@#{other_user.username} private")
    end

    its(:public_microposts) { should include public_micropost }
    its(:public_microposts) { should_not include private_micropost }
  end

  describe "following" do
    let(:other_user) { FactoryGirl.create(:user) }
    before do
      @user.save
      @user.follow!(other_user)
    end

    it { should be_following(other_user) }
    its(:followed_users) { should include(other_user) }

    describe "followed user" do
      subject { other_user }
      its(:followers) { should include(@user) }
    end

    describe "and unfollowing" do
      before { @user.unfollow!(other_user) }

      it { should_not be_following(other_user) }
      its(:followed_users) { should_not include(other_user) }
    end
  end

  describe "relationships associations" do
    before { @user.save }
    let(:other_user) { FactoryGirl.create(:user) }
    let!(:relationship) do
      @user.relationships.create!(followed_id: other_user.id) 
    end

    it "should destroy associated relationships" do
      relationships = @user.relationships
      @user.destroy
      relationships.each do |relationship|
        Relationship.find_by_id(relationship.id).should be_nil
      end
    end
  end

  describe "reverse_relationships associations" do
    before { @user.save }
    let(:other_user) { FactoryGirl.create(:user) }
    let!(:relationship) do
      @user.relationships.create!(followed_id: other_user.id) 
    end

    it "should destroy associated relationships" do
      reverse_relationships = other_user.reverse_relationships
      other_user.destroy
      reverse_relationships.each do |reverse_relationship|
        Relationship.find_by_id(reverse_relationship.id).should be_nil
      end
    end
  end

  describe "user_preference" do
    before { @user.save }
    its(:user_preference) { should_not be_nil }
    its(:receive_follower_notification?) { should be_true }
  end
end

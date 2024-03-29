require 'spec_helper'

describe Micropost do
  let(:user) { FactoryGirl.create(:user) }
  before { @micropost = user.microposts.build(content: "Lorem ipsum") }

  subject { @micropost }

  it { should respond_to(:content) }
  it { should respond_to(:user_id) }
  it { should respond_to(:user) }
  it { should respond_to(:in_reply_to_user_id) }
  it { should respond_to(:in_reply_to_user) }
  it { should respond_to(:direct_message?) }
  its(:user) { should == user }

  it { should be_valid }

  describe "when user_id is not present" do
    before { @micropost.user_id = nil }
    it { should_not be_valid}
  end

  describe "with blank content" do
    before { @micropost.content = " " }
    it { should_not be_valid }
  end

  describe "with content that is too long" do
    before { @micropost.content = "a" * 141 }
    it { should_not be_valid }
  end

  describe "in_reply_to_user" do
    let(:in_reply_to_user) { FactoryGirl.create(:user) }
    before do
      @micropost.content = "@#{in_reply_to_user.username} content" 
      @micropost.save!
    end
    
    its(:in_reply_to_user) { should == in_reply_to_user }
  end

  describe "direct_message" do
    let(:dm_user) { FactoryGirl.create(:user) }
    before do
      @micropost.content = "d@#{dm_user.username} content" 
      @micropost.save!
    end
    
    specify { @micropost.should be_direct_message }
    its(:in_reply_to_user) { should == dm_user }
  end

  describe "from_users_followed_by" do
    let(:user) { FactoryGirl.create(:user) }
    let(:other_user) { FactoryGirl.create(:user) }
    let(:third_user) { FactoryGirl.create(:user) }

    before { user.follow!(other_user) }

    let(:own_post) { user.microposts.create!(content: "foo") }
    let(:followed_post) { other_user.microposts.create!(content: "bar") }
    let(:unfollowed_post) { third_user.microposts.create!(content: "baz") }

    subject { Micropost.from_users_followed_by(user) }

    it { should include(own_post) }
    it { should include(followed_post) }
    it { should_not include(unfollowed_post) }
  end

  describe "in_reply_to" do
    let(:in_reply_to_user) { FactoryGirl.create(:user) }
    let(:in_reply_to_post) do
      in_reply_to_user.microposts.create!(content: "@#{user.username} content")
    end
    let(:unfollowed_post) do 
      in_reply_to_user.microposts.create!(content: "foo")
    end

    subject { Micropost.in_reply_to(user) }
    it { should include(in_reply_to_post) }
    it { should_not include(unfollowed_post) }
  end

  describe "from_users_followed_by_and_in_reply_to_and_direct_message" do
    let(:user) { FactoryGirl.create(:user, username: "user-1") }
    let(:other_user) { FactoryGirl.create(:user) }
    let(:third_user) { FactoryGirl.create(:user) }
    let(:in_reply_to_user) { FactoryGirl.create(:user) }

    before { user.follow!(other_user) }

    let(:own_post) { user.microposts.create!(content: "foo") }
    let(:followed_post) { other_user.microposts.create!(content: "bar") }
    let(:unfollowed_post) { third_user.microposts.create!(content: "baz") }
    let(:in_reply_to_post) do
      in_reply_to_user.microposts.create!(content: "@#{user.username} content")
    end
    let(:unfollowed_reply_post) do 
      in_reply_to_user.microposts.create!(content: "foo")
    end
    let(:direct_message_post) do
      third_user.microposts.create!(content: "d@#{user.username} content")
    end
    let(:private_post) do
      other_user.microposts.create!(content: "d@#{third_user.username} private")
    end

    subject do
      Micropost.from_users_followed_by_and_in_reply_to_and_direct_message(user)
    end

    it { should include(own_post) }
    it { should include(followed_post) }
    it { should_not include(unfollowed_post) }
    it { should include(in_reply_to_post) }
    it { should_not include(unfollowed_reply_post) }
    it { should include(direct_message_post) }
    it { should_not include(private_post) }
  end

  describe "direct_message_to" do
    let(:user) { FactoryGirl.create(:user, username: "user-1") }
    let(:dm_user) { FactoryGirl.create(:user) }
    let(:third_user) { FactoryGirl.create(:user) }

    before { user.follow!(third_user) }

    let(:direct_message_post) do
      dm_user.microposts.create!(content: "d@#{user.username} content")
    end
    let(:private_post) do
      third_user.microposts.create!(content: "d@#{dm_user.username} private")
    end

    subject { Micropost.direct_message_to(user) }

    it { should include(direct_message_post) }
  end

  describe "public_microposts_for" do
    let(:user) { Factory.create(:user) }
    let(:other_user) { Factory.create(:user) }

    let(:public_micropost) { user.microposts.create!(content: "Foo") }
    let(:private_micropost) do 
      user.microposts.create!(content: "d@#{other_user.username} private")
    end

    subject { Micropost.public_microposts_for(user) }

    it { should include public_micropost }
    it { should_not include private_micropost }
  end
end

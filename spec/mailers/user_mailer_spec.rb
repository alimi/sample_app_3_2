require "spec_helper"

describe UserMailer do
  let(:user) { Factory.create :user }

  describe "new_follower_notificaiton" do
    let(:follower) { Factory.create :user }
    before { follower.follow!(user) }
    let(:message) { UserMailer.new_follower_notification(user, follower) }

    subject { message }

    its(:subject) { should =~ /@#{follower.username} is now following you/i }
    its(:to) { should == [user.email] }
    its(:from) { should == ["do_not_reply@example.com"] }

    it "should have link to new follower profile" do
      message.parts.each do |part|
        part.body.should =~ /#{user_path(follower)}/
      end
    end
  end
end

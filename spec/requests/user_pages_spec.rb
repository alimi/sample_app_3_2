require 'spec_helper'

describe "UserPages" do
  subject { page }

  describe "index" do
    let(:user) { FactoryGirl.create(:user) }

    before do
      sign_in user 
      visit users_path
    end

    it { should have_selector('title', text: 'All users') }

    describe "pagination" do
      before(:all) { 30.times { FactoryGirl.create(:user) } }
      after(:all) { User.delete_all }

      let(:first_page) { User.paginate(page: 1) }
      let(:second_page) { User.paginate(page: 2) }

      it { should have_link('Next') }
      it { should have_link('2') }
      it { should_not have_link('delete') }

      describe "as an admin user" do
        let(:admin) { FactoryGirl.create(:admin) }
        before do
          sign_in admin
          visit users_path
        end

        it { should have_link('delete', href: user_path(User.first)) }
        it { should_not have_link('delete', href: user_path(admin)) }

        it "should be able to delete anohter user" do
          expect { click_link('delete') }.to change(User, :count).by(-1)
        end

        it "should not be able to delete self" do
          expect { delete user_path(admin) }.not_to change(User, :count).by(-1) 
        end
      end

      it "should list each user" do
        User.all[0..2].each do |user|
          page.should have_selector('li', text: user.name)
        end
      end

      it "should list the first page of users" do
        first_page.each do |user|
          page.should have_selector('li', text: user.name)
        end
      end

      it "should not list the second page of users" do
        second_page.each do |user|
          page.should_not have_selector('li', text: user.name)
        end
      end
    end
  end

  describe "profile page" do
    let(:user) { FactoryGirl.create(:user) }
    let(:other_user) { FactoryGirl.create(:user) }
    let!(:m1) { FactoryGirl.create(:micropost, user: user, content: "Foo") }
    let!(:m2) { FactoryGirl.create(:micropost, user: user, content: "Bar") }
    let!(:m3) do
      FactoryGirl.create(:micropost, user: user,
        content: "d@#{other_user.username} private")
    end

    before { visit user_path(user) }

    it { should have_selector('li', text: user.name) }
    it { should have_title(user.name) }

    describe "microposts" do
      it { should have_content(m1.content) }
      it { should have_content(m2.content) }
      it { should_not have_content(m3.content) }
      it { should have_content("Microposts #{user.microposts.count - 1}") }

      describe "micropost pagination" do
        before do 
          30.times{ Factory.create(:micropost, user: user, content: "Foo") }
          visit user_path(user)
        end

        it { should have_link('Next') }
        it { should have_link('2') }
      end
    end

    describe "follower/following counts" do
      let(:other_user) { FactoryGirl.create(:user) }
      before do
        other_user.follow!(user)
        visit user_path(user)
      end

      it { should have_link("0 following", href: following_user_path(user)) }
      it { should have_link("1 follower", href: followers_user_path(user)) }
    end

    describe "follow/unfollow buttons" do
      let(:other_user) { FactoryGirl.create(:user) }
      before{ sign_in user }

      describe "following a user" do
        before { visit user_path(other_user) }

        it "should increment the followed user count" do
          expect do
            click_button "Follow"
          end.to change(user.followed_users, :count).by(1)
        end

        it "should increment the other user's followers count" do
          expect do
            click_button "Follow"
          end.to change(other_user.followers, :count).by(1)
        end

        describe "toggling the button" do
          before { click_button "Follow" }
          it { should have_selector('input', value: 'Unfollow') }
        end
      end

      describe "unfollowing a user" do
        before do
          user.follow!(other_user)
          visit user_path(other_user)
        end 

        it "should decrement the followed user count" do
          expect do
            click_button "Unfollow"
          end.to change(user.followed_users, :count).by(-1)
        end

        it "should decrement the other user's followers count" do
          expect do
            click_button "Unfollow"
          end.to change(other_user.followers, :count).by(-1)
        end

        describe "toggling the button" do
          before { click_button "Unfollow" }
          it { should have_selector('input', value: 'Follow') }
        end
      end
    end
  end

  describe "user info sidebar" do
    let(:user) { FactoryGirl.create(:user) }

    describe "micropost section" do
      let!(:m1) { FactoryGirl.create(:micropost, user: user, content: "Foo") }

      describe "with micropost count of one" do
        before { visit user_path(user) }
        it{ should have_content "Microposts 1" }
      end

      describe "with micropost count of one" do
        let!(:m2) { FactoryGirl.create(:micropost, user: user, content: "Bar") }
        before { visit user_path(user) }
        it{ should have_content "Microposts 2" }
      end
    end
  end

  describe "signup page" do
    before { visit signup_path }

    it { should have_selector('h1', text: 'Sign up') }
    it { should have_title(full_title('Sign up')) }
  end

  describe "signup" do
    before { visit signup_path }

    describe "with invalid information" do
      it "should not create a user" do
        expect { click_button "Sign up" }.not_to change(User, :count)
      end
    end

    describe "with valid information" do
      before do
        fill_in "Name",         with: "Example User"
        fill_in "Email",        with: "user@example.com"
        fill_in "Username",     with: "example"
        fill_in "Password",     with: "foobar"
        fill_in "Confirmation", with: "foobar"
      end

      it "should create a user" do
        expect { click_button "Sign up" }.to change(User, :count).by(1)
      end 

      describe "after saving the user" do
        before { click_button "Sign up" }
        let(:user) { User.find_by_email('user@example.com') }

        it { should have_title(user.name) }
        it { should have_selector('div.flash.success', text: 'Welcome') }
        it { should have_link('Sign out') }
      end
    end
  end

  describe "edit" do
    let(:user) { FactoryGirl.create(:user) }
    before do
      sign_in user
      visit edit_user_path(user) 
    end

    describe "page" do
      it { should have_selector('h1', text: "Edit user") }
      it { should have_selector('title', text: "Edit user") }
      it { should have_link('change', href: 'http://gravatar.com/emails') }
    end

    describe "with invalid information" do
      let(:error) { '1 error prohibited this user from being saved' }
      before { click_button "Update" }

      it { should have_content(error) }
    end

    describe "with valid information" do
      let(:user) { FactoryGirl.create(:user) }
      let(:new_name) { "New name" }
      let(:new_email) { "new@example.com" }
      
      before do
        fill_in "Name",         with: new_name
        fill_in "Email",        with: new_email
        fill_in "Password",     with: user.password
        fill_in "Confirmation", with: user.password
        click_button "Update"
      end

      it { should have_selector('title', text: new_name) }
      it { should have_selector('div.flash.success') }
      it { should have_link('Sign out', :href => signout_path) }
      specify { user.reload.name.should == new_name }
      specify { user.reload.email.should == new_email }
    end
  end

  describe "following/followers" do
    let(:user) { FactoryGirl.create(:user) }
    let(:other_user) { FactoryGirl.create(:user) }
    before { user.follow!(other_user) }

    describe "followed_users" do
      before do
        sign_in user
        visit following_user_path(user)
      end
      
      it { should have_selector('a', href: user_path(other_user),
                                     text: other_user.name) }
    end

    describe "followers" do
      before do
        sign_in other_user
        visit followers_user_path(other_user)
      end

      it { should have_selector('a', href: user_path(user),
                                     text: user.name) }
    end
  end
end

describe "visting another user's page" do
  let(:signed_in_user) { Factory.create :user }
  let(:other_user) { Factory.create :user }
  let!(:micropost) { Factory.create :micropost, user: other_user, content: "Foo" }

  before do 
    sign_in signed_in_user
    visit user_path(other_user) 
  end

  describe "should not see delete link for another user's micropost" do
    it { should_not have_link('delete', href: micropost_path(micropost)) }
  end
end

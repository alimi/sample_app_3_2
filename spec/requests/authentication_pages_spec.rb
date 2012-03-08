require 'spec_helper'

describe "AuthenticationPages" do
  subject { page }

  describe "sigin page" do
    before { visit signin_path }

    it { should have_selector('h1', text: 'Sign in') }
    it { should have_title('Sign in') }

    describe "with invalid information" do
      before { click_button "Sign in" }

      it { should have_title('Sign in') }
      it { should have_error_message('Invalid') }

      it { should_not have_link('Users', href: users_path) }
      it { should_not have_link('Profile') }
      it { should_not have_link('Settings') }
      it { should_not have_link('Sign out', href: signout_path) }

      describe "after visiting another page" do
        before { click_link "Home" }
        it { should_not have_error_message }
      end
    end

    describe "with valid informaiton" do
      let(:user) { FactoryGirl.create(:user) }

      before { valid_signin(user) }

      it { should have_title(user.name) }

      it { should have_link('Users', href: users_path) }
      it { should have_link('Profile', href: user_path(user)) }
      it { should have_link('Settings', href: edit_user_path(user)) }
      it { should have_link('Sign out', href: signout_path) }
      it { should_not have_link('Sign in', href: signin_path) }

      describe "followed by signout" do
        before { click_link "Sign out" }
        it { should have_link('Sign in') }
      end
    end
  end

  describe "authorization" do
    describe "for non-signed-in users" do
      let(:user) { Factory(:user) }

      describe "in the Users controller" do
        describe "visiting the edit page" do
          before { visit edit_user_path(user) }
          it { should have_selector('title', text: 'Sign in') }
        end

        describe "submitting to the update action" do
          before { put user_path(user) }
          specify { response.should redirect_to(signin_path) }
        end
      end

      describe "when attempting to visit a protected page" do
        before do
          visit edit_user_path(user)
          fill_in "Email", with: user.email
          fill_in "Password", with: user.password
          click_button "Sign in"
        end

        describe "after signing in" do
          it "should render the desired protected page" do
            page.should have_selector('title', text: 'Edit user')
          end

          describe "after signing in again" do
            before { sign_in user }
            it "should render default (profile) page" do
              page.current_path.should == user_path(user)
            end
          end
        end
      end

      describe "visiting user index" do
        before { visit users_path }
        it { should have_selector('title', text: 'Sign in') }
      end
    end

    describe "as wrong user" do
      let(:user) { FactoryGirl.create(:user) }
      let(:wrong_user) { FactoryGirl.create(:user, email: "wrong@example.com") }
      before { sign_in user }

      describe "visiting Users#edit page" do
        before { visit edit_user_path(wrong_user) }
        it { should have_selector('title', text: 'Home') }
      end

      describe "submitting a PUT request to the Users#update action" do
        before { put user_path(wrong_user) }
        specify { response.should redirect_to(root_path) }
      end
    end

    describe "as non-admin user" do
      let(:user) { FactoryGirl.create(:user) }
      let(:non_admin) { FactoryGirl.create(:user) }

      before { sign_in non_admin }

      describe "submitting a DELETE request to Users#destroy action" do
        before { delete user_path(user) }
        specify { response.should redirect_to(root_path) } end
    end

    describe "as signed in user" do
      let(:user) { FactoryGirl.create(:user) }
      before { sign_in user }

      describe "visiting Users#new page" do
        before { visit new_user_path }
        specify { current_path.should == root_path }
      end

      describe "submitting a POST to Users#create action" do
        before { post users_path }
        specify { response.should redirect_to(root_path) }
      end
    end
  end
end

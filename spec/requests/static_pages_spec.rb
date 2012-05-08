require 'spec_helper'

describe "StaticPages" do

  subject { page }
  
  shared_examples_for "all static pages" do
    it { should have_selector('h1', text: heading) }
    it { should have_selector('title', text: full_title(page_title)) }
  end

  describe "Home page" do
    before { visit root_path }
    let(:heading) { 'Sample App' }
    let (:page_title) { 'Home' }

    it_should_behave_like "all static pages"

    describe "for signed-in users" do
      let(:user) { FactoryGirl.create(:user) }
      let(:other_user) { FactoryGirl.create(:user) }
      let(:dm_user) { FactoryGirl.create(:user) }
      let!(:micropost_reply) do 
        FactoryGirl.create(:micropost, user: other_user, 
                           content: "@#{user.username} content")
      end
      let!(:direct_message) do 
        FactoryGirl.create(:micropost, user: dm_user, 
                           content: "d@#{user.username} content")
      end

      before do
        other_user.follow!(user)
        FactoryGirl.create(:micropost, user: user, content: "Lorem ipsum")
        FactoryGirl.create(:micropost, user: user, content: "Dolor sit amet")
        sign_in user
        visit root_path
      end

      describe "user feed" do
        it "should render the feed" do
          user.feed.each do |item|
            page.should have_selector("tr##{item.id}", text: item.content)
          end
        end

        it "should include @replies" do
          page.should have_selector("tr##{micropost_reply.id}", 
                                    text: micropost_reply.content)
        end

        it "should include direct messages" do
          page.should have_selector("tr##{direct_message.id}", 
                                    text: direct_message.content)
        end
      end

      it { should have_link("0 following", href: following_user_path(user)) }
      it { should have_link("1 follower", href: followers_user_path(user)) }
    end
  end

  describe "Help page" do
    before { visit help_path }
    let(:heading) { 'Help' }
    let (:page_title) { 'Help' }

    it_should_behave_like "all static pages"
  end

  describe "About page" do
    before { visit about_path }
    let(:heading) { 'About Us' }
    let (:page_title) { 'About Us' }

    it_should_behave_like "all static pages"
  end

  describe "Contact page" do
    before { visit contact_path }
    let(:heading) { 'Contact' }
    let (:page_title) { 'Contact' }

    it_should_behave_like "all static pages"
  end

  it "should have the right links on the layout" do
    visit root_path
    click_link "About"
    page.should have_selector 'title', text: full_title('About Us')
    click_link "Help"
    page.should have_selector 'title', text: full_title('Help')
    click_link "Contact"
    page.should have_selector 'title', text: full_title('Contact')
    click_link "Home"
    page.should have_selector 'title', text: full_title('Home')
    click_link "Sign up now!"
    page.should have_selector 'title', text: full_title('Sign up')
  end
end

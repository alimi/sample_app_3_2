def full_title(page_title)
  base_title = "Ruby on Rails Tutorial Sample App"
  if page_title.empty?
    base_title
  else
    "#{base_title} | #{page_title}"
  end
end

def valid_signin(user)
  fill_in "Username", with: user.username
  fill_in "Password", with: user.password
  click_button "Sign in"
end

RSpec::Matchers.define :have_error_message do |message|
  match do |page|
    page.should have_selector('div.flash.error', text: message)
  end
end

RSpec::Matchers.define :have_title do |name|
  match do |page|
    page.should have_selector('title', text: name)
  end
end

def sign_in(user)
  visit signin_path
  fill_in "Username", with: user.username
  fill_in "Password", with: user.password
  click_button "Sign in"
  # Sign in when not using Capybara as well
  cookies[:remember_token] = user.remember_token
end

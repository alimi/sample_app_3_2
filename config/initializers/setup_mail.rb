ActionMailer::Base.smtp_settings = {
  :address              => "smtp.gmail.com",
  :port                 => 587,
  :domain               => "google.com",
  :user_name            => ENV['EMAIL_USER'],
  :password             => ENV['EMAIL_PSWD'],
  :authentication       => "plain",
  :enable_starttls_auto => true
}

if Rails.env.development?
  class DevelopmentMailInterceptor
    def self.delivering_email(message)
      message.subject = "[Sample_App] [#{message.to}] [#{message.subject}]"
      message.to = "alimidev@gmail.com"
    end
  end

  ActionMailer::Base.register_interceptor(DevelopmentMailInterceptor)
end

if Rails.env.production?
  ActionMailer::Base.default_url_options[:host] = "blooming-window-9993.herokuapp.com"
else
  ActionMailer::Base.default_url_options[:host] = "localhost:3000"
end

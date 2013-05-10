require 'securerandom'

class VlineProviderGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("../templates", __FILE__)

  argument :name, :type => :string, :default => 'Vline'

  class_option :service_id, :type => :string, :required => true,
               :desc => 'Your vLine Service ID'
  class_option :client_id, :type => :string, :default => SecureRandom.urlsafe_base64(32),
               :desc => 'OAUTH client ID'
  class_option :client_secret, :type => :string, :default => SecureRandom.urlsafe_base64(32),
               :desc => 'OAUTH client secret'
  class_option :provider_secret, :type => :string, :required => true,
               :desc => 'Secret string for signing login and OAUTH tokens. This value comes from developer console.'

  desc 'Creates a VlineProvider controller.'

  def check_class_collisions
    class_collisions class_path, "#{class_name}Controller"
  end

  def copy_controller_file
    template 'controller.rb', File.join('app/controllers', class_path, "#{file_name}_controller.rb")
  end

  def copy_initializer_file
    template 'initializer.rb', "config/initializers/#{file_name}.rb"
  end

  def add_routes
    route "match '_vline/launch' => 'vline#launch', :via => :all"
    route "match '_vline/api/v1/oauth/authorize' => 'vline#authorize', :via => :all"
    route "mount Vline::API => '_vline/api'"
  end

  def add_jsonp_support
    line = "# This file is used by Rack-based servers to start the application."
    gsub_file 'config.ru', /(#{Regexp.escape(line)})/mi do |match|
      "#{match}\nrequire 'rack/jsonp'\nuse Rack::JSONP\n"
    end
  end

  def output
    say_status "Service ID", "#{options[:service_id]}", :blue
    say_status "Client ID", "#{options[:client_id]}", :blue
    say_status "Client Secret", "#{options[:client_secret]}", :blue
  end

  protected
    def login_filter
      if File.exist? 'config/initializers/devise.rb'
        "before_filter :authenticate_user!"
      elsif File.exist? 'config/initializers/authlogic.rb'
        "before_filter :require_user"
      else
        "before_filter :login_required"
      end
    end
end

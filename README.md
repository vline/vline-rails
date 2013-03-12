# vLineRails Plugin

vLineRails is a plugin that allows any Rails app to act as a vLine Identity Provider. Every vLine application instance
has at least one registered Identity Provider, which is responsible for authenticating users and providing access to their
contact lists and group memberships. The [Identity Provider interface](https://vline.com/developer/docs/identity_providers)
is a subset of OAuth 2.0 and OpenSocial 2.5.

Learn more about vLine applications at: https://vline.com/developer

## Before you begin

Before installing the plugin, you'll need to:

1. Sign up for a vLine account at https://vline.com

2. Login to the [Developer Console](https://vline.com/developer) and click `Create Application`

3. Choose a name for your application.

## Testing Locally

For the vLine servers to be able to make api calls to your provider, your rails app will need to be running on a
publicly accessible server. If your development server is behind a firewall, you can make it publicly accessible
with [Forward](http://forwardhq.com):

    gem install forward
    forward 3000

If your provider suddenly stops working, check to make sure forward is still running and
your server is accessible at the forward url.

## Installation (Rails 3.0)

1. Add the plugin to your Gemfile:

        gem 'vline-rails'

1. Install it:

        bundle install

1. Generate the provider by running the following command:

        rails generate vline_provider --app-id=Your-App-Id --provider-secret=Your-App-Secret
    
    Make note of the `Client Id` and `Client Secret` output by the command.

1. Review the generated VlineProviderController, making any changes necessary to work with your models, authentication
framework, and authorization framework.

        vim app/controllers/vline_controller.rb

## Configure your app

1. Open up the vLine Developer Console and choose `Hosted App Settings`.

1. You'll notice there are default URLs set for images used by the app. You can leave these as-is or change them to
custom images for your app.

1. Select `Custom OAuth` in the `Authorization` dropdown:
    * Add the `Client Id` and `Client Secret` from the `rails generate` command you previously ran.
    * Set the `Provider URL` to : `https://your-forward-url/_vline/api/v1/`
    * Set the `OAuth URL` to: `https://your-forward-url/_vline/api/v1/oauth/`


## Usage

You can now launch into your vLine application from any view.

To launch to the application home page:

    <%= vline_launch 'Launch' %>

To launch to a particular user's chat page:

    <%= vline_launch 'Launch', @userId %>

## Notes

* If you are using the Deflater gem to gzip content, make sure it comes before `Rack::JSONP` in the `config.ru`:

        require 'rack/jsonp'
        use Rack::Deflater
        use Rack::JSONP
        require ::File.expand_path('../config/environment',  __FILE__)
        run YourApp::Application

* It's common to need to test changes before rolling them out directly to your users. We suggest creating two vLine
applications, one of which you can use to test out changes before rolling them out to your users (e.g.,
`myapp` and `myapp-dev`).

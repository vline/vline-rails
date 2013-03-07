require 'grape'
require 'jwt'

module Vline
  mattr_accessor :app_id
  @@app_id = nil

  mattr_accessor :provider_id
  @@provider_id = nil

  mattr_accessor :provider_secret
  @@provider_secret = nil

  mattr_accessor :client_id
  @@client_id = nil

  mattr_accessor :client_secret
  @@client_secret = nil

  mattr_accessor :client_callback_url_base
  @@client_callback_url_base = "https://api.vline.com/v1/auth"

  mattr_accessor :access_token_exp_time
  @@access_token_exp_time = nil

  mattr_accessor :request_token_exp_time
  @@request_token_exp_time = 10.minutes

  mattr_accessor :login_token_exp_time
  @@login_token_exp_time = 2.weeks

  module Helper
    def vline_launch(content, userId=nil)
      link_to(content, {:action => 'launch', :controller => '/vline', :userId => userId}, :target => '_blank')
    end
  end

  module AuthError
    INVALID_REQUEST = "invalid_request"
    ACCESS_DENIED = "access_denied"
    UNAUTHORIZED_CLIENT= "unauthorized_client"
    UNSUPPORTED_RESPONSE_TYPE = "unsupported_response_type"
    INVALID_SCOPE = "invalid_scope"
    SERVER_ERROR = "server_error"
    TEMPORARILY_UNAVAILABLE = "temporarily_unavailable"
  end

  class API < Grape::API
    version 'v1', :using => :path
    format :json

    def self.err_response(e, status)
      Rack::Response.new({
         'status' => status,
         'message' => e.message
       }.to_json, status)
    end

    rescue_from ActiveRecord::RecordNotFound do |e|
      API.err_response(e, 404)
    end

    rescue_from :all do |e|
      API.err_response(e, 500)
    end

    helpers do
      def validate_request_token(token)
        validate_token('req', token)
      end

      def validate_access_token(token)
        validate_token('auth', token)
      end

      def validate_token(type, token)
        obj = JWT.decode(token, JWT.base64url_decode(Vline.provider_secret))
        if obj['type'] != type
          raise 'Invalid token type'
        end
        if obj['exp'] && (Time.now.to_i > obj['exp'])
          raise 'Token expired'
        end
        @current_user_id = obj['id']
      end

      def authenticate!
        token = params[:access_token]
        if !token
          raise 'access_token not found'
        end
        validate_access_token(token)
        @provider = VlineController.new(@current_user_id)
      end

      def userId
        userId = params[:userId];
        if userId == '@me'
          @current_user_id
        else
          userId
        end
      end
    end

    desc "Returns an access token"
    params do
      requires :client_id, :type => String, :desc => 'OAuth client id'
      requires :client_secret, :type => String, :desc => 'OAuth client secret'
      requires :code, :type => String, :desc => 'Request token'
    end
    post '/oauth/access_token' do
      if params[:client_id] != Vline.client_id
        raise 'Invalid client_id'
      end
      if params[:client_secret] != Vline.client_secret
        raise 'Invalid client_secret'
      end
      userId = validate_request_token(params[:code])
      token = Vline.create_access_token(userId)
      "access_token=#{token}&token_type=bearer"
    end

    desc "Returns a user's profile"
    params do
      requires :userId, :type => String, :desc => 'User ID of person'
    end
    get '/people/:userId/@self' do
      authenticate!
      @provider.get_profile(userId)
    end

    desc "Returns a collection of all contacts connected to a user"
    params do
      requires :userId, :type => String, :desc => 'User ID of person'
    end
    get '/people/:userId/@all' do
      authenticate!
      @provider.get_contact_profiles(userId)
    end
  end

  def self.setup
    yield self
  end

  def self.launch_url_for(userId, targetUserId=nil)
    token = create_request_token(userId)
    launch_url = auth_url
    if targetUserId
      launch_url += "/#{targetUserId}"
    end
    launch_url += "?code=#{token}"
  end

  def self.auth_url
    "#{Vline.client_callback_url_base}/#{Vline.app_id}/#{Vline.provider_id}"
  end

  def self.auth_error_redirect_url(error, state)
    url = auth_url + "?error=" + error
    if state
      url += "&state=" + state
    end
    url
  end

  def self.create_request_token(userId)
      create_token('req', userId, Vline.request_token_exp_time)
  end

  def self.create_login_token(userId)
    payload = {'sub'=> Vline.provider_id + ':' + userId.to_s, 'iss'=> Vline.provider_id}
    add_expiration(payload, Vline.login_token_exp_time)
    JWT.encode(payload, JWT.base64url_decode(Vline.provider_secret))
  end

  private
    def self.add_expiration(payload, exp_time)
      payload['exp'] = Time.now.to_i + exp_time
    end

    def self.create_access_token(userId)
      create_token('auth', userId, Vline.access_token_exp_time)
    end

    def self.create_token(type, userId, exp_time)
      payload = {'type' => type, 'id' => userId}
      if exp_time
        add_expiration(payload, exp_time)
      end
      JWT.encode(payload, JWT.base64url_decode(Vline.provider_secret))
    end
end

ActionView::Base.send :include, Vline::Helper

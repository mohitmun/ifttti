class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # protect_from_forgery with: :exception

  def youtube_liked
    params.permit!
    receipe = Receipe.create(user_id: 1, content: {extract_and_send: {title: params["title"], url: params["url"]}})
    receipe.delay.extract_and_send
    render json: {message: "ok"}, status: 200
  end

  def connect_goodreads
    callback_url = ENV["ROOT_URL"] + '/oauth/callback/goodreads'
    consumer = OAuth::Consumer.new(ENV["GOODREADS_KEY"],ENV["GOODREADS_SECRET"],site: "http://www.goodreads.com")
    request_token = consumer.get_request_token
    session[:request_token] = request_token
    session[:token_secret] = request_token.secret
    redirect_to request_token.authorize_url(:oauth_callback => callback_url)
  end

  def connect_google
    credentials = User.initialize_google_credentials
    redirect_to credentials.authorization_uri.to_s
  end

  def oauth_callback_goodreads
    hash = { oauth_token: session[:token], oauth_token_secret: session[:token_secret]}
    consumer = OAuth::Consumer.new(
      ENV["GOODREADS_KEY"],
      ENV["GOODREADS_SECRET"],
      site: "http://www.goodreads.com"
    )
    request_token  = OAuth::RequestToken.from_hash(consumer, session[:request_token])
    access_token = request_token.get_access_token
    client = Goodreads.new(oauth_token: access_token)
  end

  def oauth2_callback_google
    credentials = User.initialize_google_credentials
    credentials.code = params["code"]
    credentials.fetch_access_token!
    user = User.save_from_google_user(credentials)
    sign_in(:user, user)
    redirect_to root_url
  end

  def file
    params.permit!
    file_name = params["name"]
    send_file("#{Rails.root}/tmp/#{file_name}")
  end

  def index
    
  end
end

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # protect_from_forgery with: :exception
  before_filter :login_if_not, :except => [:connect_google, :oauth2_callback_google, :youtube_liked, :send_to_telegram]

  def login_if_not
    if !user_signed_in?
      session[:redirect_to] = request.path
      redirect_to "/connect/google"
    end
  end

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
    session[:token] = request_token.token
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
    request_token  = OAuth::RequestToken.from_hash(consumer, hash)
    access_token = request_token.get_access_token
    client = Goodreads.new(oauth_token: access_token)
    current_user.content[:goodreads].merge!(access_token_hash: {oauth_token: access_token.token, oauth_token_secret: access_token.secret})
    current_user.save
  end

  def oauth2_callback_google
    credentials = User.initialize_google_credentials
    credentials.code = params["code"]
    credentials.fetch_access_token!
    user = User.save_from_google_user(credentials)
    sign_in(:user, user)
    if session[:redirect_to]
      redirect_to session[:redirect_to]
    else
      redirect_to root_url
    end
  end

  def send_to_telegram
    title = params[:title]
    content = params[:content]
    link = params[:link]
    RestClient.post("https://api.telegram.org/bot287297665:AAGf5sJQeRa_l8-JGre-GkwTtaXV-3IDGH4/sendMessage", {"chat_id": 230551077, "text": "*#{title}*\n#{content} [link](#{link})", parse_mode: "Markdown", disable_web_page_preview: true})
    head :ok
  end

  def file
    params.permit!
    file_name = params["name"]
    send_file("#{Rails.root}/tmp/#{file_name}")
  end

  def index
    
  end
end

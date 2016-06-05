require 'google/apis/oauth2_v2/representations.rb'
require 'google/apis/oauth2_v2/service.rb'
require 'google/apis/oauth2_v2/classes.rb'
class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  after_initialize :init

  def init
    self.content ||= {}
    self.content.deep_symbolize_keys!
  end

  def get_google_credentials
    credentials = User.initialize_google_credentials
    auth_url = credentials.authorization_uri
    credentials.access_token = self.content[:google][:access_token]
    # credentials.fetch_access_token!
  end

  def get_gdrive_session
    credentials = get_google_credentials
    GoogleDrive.login_with_oauth(credentials)
  end

  def self.initialize_google_credentials
    credentials = Google::Auth::UserRefreshCredentials.new(
    client_id: "787759552043-ilstjfmfo9ehoqp6g825fu5vp5ne10iq.apps.googleusercontent.com",
    client_secret: "K58Xh01uUO5PPssjPWS3wUwy",
    scope: [
          "https://www.googleapis.com/auth/userinfo.email",
          "https://www.googleapis.com/auth/userinfo.profile",
         "https://www.googleapis.com/auth/drive",
         "https://spreadsheets.google.com/feeds/",
       ],
    redirect_uri: "#{ENV["ROOT_URL"]}/oauth2/callback/google/")
  end

  def self.save_from_google_user(credentials)
    authservice = Google::Apis::Oauth2V2::Oauth2Service.new
    authservice.authorization = credentials
    userinfo = authservice.get_userinfo_v2(fields: "email")
    user = User.find_by(email: userinfo.email)
    if user
      user.content[:google][:access_token] = credentials.access_token
      user.save
    else
      user = User.create(email: userinfo.email, password: SecureRandom.hex, content: {google: {access_token: credentials.access_token}})
    end
    return user
  end
end

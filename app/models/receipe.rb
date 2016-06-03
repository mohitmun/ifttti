require "google_drive"
class Receipe < ActiveRecord::Base

  IFTTT_MAKER_POST_LINK_YOUTUBE = "https://maker.ifttt.com/trigger/youtube_video_file_link/with/key/cQCRNcVBFKNs9Bl6u6OLvE"

  after_initialize :init

  def init
    content.deep_symbolize_keys!
  end


  def extract_and_send(root_url)
    file_name = Random.rand(100)
    data = content[:extract_and_send]
    json_info = JSON.parse(`youtube-dl -j #{data[:url]}`)
    if json_info["categories"].include?("Music")
      puts "Music video detected"
      additional_params = "--extract-audio --audio-format mp3"
      ext = "mp3"
    else
      puts "Downloading video in mp4 format"
      additional_params = "-f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4'"
      ext = "mp4"
    end
    `youtube-dl #{additional_params} -o '#{Rails.root}/tmp/#{file_name}.%(ext)s' '#{data[:url]}'`
    #Test `youtube-dl --extract-audio --audio-format mp3 -o '#{Rails.root}/public/test.%(ext)s' https://www.youtube.com/watch?v=foE1mO2yM04`
    session = get_gdrive_session
    file = session.upload_from_file("#{Rails.root}/tmp/#{file_name}.#{ext}", "#{file_name}.#{ext}", convert: false)
    file.acl.push({ scope_type: 'anyone', with_key: true, role: 'reader' })
    response = RestClient.post Receipe::IFTTT_MAKER_POST_LINK_YOUTUBE, {"value1": file.api_file.web_content_link, "value2": data[:title]}.to_json, :content_type => :json, :accept => :json
    #http.request(request)
  end

  def get_gdrive_session
    credentials = Google::Auth::UserRefreshCredentials.new(
    client_id: "452925651630-egr1f18o96acjjvphpbbd1qlsevkho1d.apps.googleusercontent.com",
    client_secret: "1U3-Krii5x1oLPrwD5zgn-ry",
    scope: [
         "https://www.googleapis.com/auth/drive",
         "https://spreadsheets.google.com/feeds/",
       ],
    redirect_uri: "http://ifttti.herokuapp.com")
    auth_url = credentials.authorization_uri
    credentials.refresh_token = ENV["REFRESH_TOKEN"]
    credentials.fetch_access_token!
    session = GoogleDrive.login_with_oauth(credentials)
  end

end

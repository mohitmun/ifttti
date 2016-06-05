require "google_drive"
class Receipe < ActiveRecord::Base

  IFTTT_MAKER_POST_LINK_YOUTUBE = "https://maker.ifttt.com/trigger/youtube_video_file_link/with/key/cQCRNcVBFKNs9Bl6u6OLvE"

  after_initialize :init

  def init
    content.deep_symbolize_keys!
    @session = get_gdrive_session
  end


  def extract_and_send
    data = content[:extract_and_send]
    json_info = JSON.parse(`youtube-dl -j #{data[:url]}`)
    file_name = json_info["fulltitle"]
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
    file = upload_to_drive("#{Rails.root}/tmp/#{file_name}.#{ext}", "#{file_name}.#{ext}", "DriveSyncFiles")
    response = RestClient.post Receipe::IFTTT_MAKER_POST_LINK_YOUTUBE, {"value1": file.api_file.web_content_link, "value2": data[:title]}.to_json, :content_type => :json, :accept => :json
    #http.request(request)
  end

  def upload_to_drive(local_path, file_name, remote_folder = nil, public = true)
    file = @session.upload_from_file(local_path, file_name, remote_folder)
    if public
      file.acl.push({ scope_type: 'anyone', with_key: true, role: 'reader' })
    end
    return file
  end

  def get_gdrive_session
    credentials = Google::Auth::UserRefreshCredentials.new(
    client_id: "787759552043-jf4erg7797stgn0td73iq54j78o6mrii.apps.googleusercontent.com",
    client_secret: "E3O4mK47Fu9Ykx9q7OOTTQAi",
    scope: [
         "https://www.googleapis.com/auth/drive",
         "https://spreadsheets.google.com/feeds/",
       ],
    redirect_uri: "http://ifttti.herokuapp.com/oauth2/callback")
    auth_url = credentials.authorization_uri
    credentials.refresh_token = ENV["REFRESH_TOKEN"]
    credentials.fetch_access_token!
    GoogleDrive.login_with_oauth(credentials)
  end

end

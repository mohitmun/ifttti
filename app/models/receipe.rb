require "google_drive"
class Receipe < ActiveRecord::Base

  IFTTT_MAKER_POST_LINK_YOUTUBE = "https://maker.ifttt.com/trigger/youtube_video_file_link/with/key/cQCRNcVBFKNs9Bl6u6OLvE"

  after_initialize :init
  belongs_to :user

  def init
    content.deep_symbolize_keys!
  end

  def set_log(new_log)
    logs = content[:logs] || []
    logs << new_log
    self.content[:logs] = logs
    self.save
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
    file = user.upload_to_drive("#{Rails.root}/tmp/#{file_name}.#{ext}", "#{file_name}.#{ext}", "Youtube Downloads")
    response = RestClient.post Receipe::IFTTT_MAKER_POST_LINK_YOUTUBE, {"value1": file.api_file.web_content_link, "value2": data[:title]}.to_json, :content_type => :json, :accept => :json
    set_log("IFTTT_MAKER_POST_LINK_YOUTUBE response: #{response}")
    #http.request(request)
  end
end

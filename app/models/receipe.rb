class Receipe < ActiveRecord::Base

  IFTTT_MAKER_POST_LINK_YOUTUBE = "https://maker.ifttt.com/trigger/youtube_video_file_link/with/key/cQCRNcVBFKNs9Bl6u6OLvE"

  after_initialize :initialize

  def initialize
    content.deep_symbolize_keys!
  end


  def extract_and_send(root_url)
    file_name = Random.rand(100)
    data = content[:extract_and_send]
    json_info = JSON.parse(`youtube-dl -j #{data[:url]}`)
    if json_info["categories"].include?("Music")
      puts "Music video detected"
      additional_params = "--extract-audio --audio-format mp3"
    else
      puts "Downloading video in mp4 format"
      additional_params = "-f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4'"
    end
    `youtube-dl #{additional_params} -o '#{Rails.root}/public/#{file_name}.%(ext)s' '#{data[:url]}'`
    #Test `youtube-dl --extract-audio --audio-format mp3 -o '#{Rails.root}/public/test.%(ext)s' https://www.youtube.com/watch?v=foE1mO2yM04`
    url = URI(Receipe::IFTTT_MAKER_POST_LINK_YOUTUBE)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new(url)
    request["content-type"] = 'application/json'
    file_url = root_url + "#{file_name}.mp3"
    puts "*"*100
    puts "root: #{file_url}"
    puts "*"*100
    request.body = {"value1": file_url, "value2": data[:title]}.to_json
    response = http.request(request)
  end

end

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # protect_from_forgery with: :exception
  before_filter :set_var

  def set_var
    @ifttt_maker_post_link_youtube = "https://maker.ifttt.com/trigger/youtube_video_file_link/with/key/cQCRNcVBFKNs9Bl6u6OLvE"
  end


  def youtube_liked
    url = URI("http://www.youtubeinmp3.com/fetch/?format=JSON&video=#{params['url']}")
    http = Net::HTTP.new(url.host, url.port)
    request = Net::HTTP::Get.new(url)
    # "{\n    \"campaign_id\": \"c7947ce4-5ad0-4b79-a5ac-d24884432c79\",\n    \"user_ids\": [\"bbfb6a8c-1dba-465b-bcb4-297eec82371f\"]\n}"
    response = http.request(request)
    response.body
    result = JSON.parse(response.body)
    
    render json: {message: "ok"}, status: 200
    puts "wowow: #{params}"
    `youtube-dl --extract-audio --audio-format mp3 -o '#{Rails.root}/public/#{result["title"]}.%(ext)s' '#{params['url']}'`

    url = URI(@ifttt_maker_post_link_youtube)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new(url)
    request["content-type"] = 'application/json'
    file_url = root_url + "#{URI.escape(result["title"])}.mp3"
    puts "*"*100
    puts "root: #{file_url}"
    puts "*"*100
    request.body = {"value1": file_url, "value2": result["title"]}.to_json
    response = http.request(request)
  end

  def index
    
  end
end

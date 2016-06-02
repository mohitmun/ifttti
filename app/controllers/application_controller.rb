class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # protect_from_forgery with: :exception

  def youtube_liked
    params.permit!
    receipe = Receipe.create(content: {extract_and_send: {title: params["title"], url: params["url"]}})
    receipe.delay.extract_and_send(root_url)
    render json: {message: "ok"}, status: 200
  end

  def file
    params.permit!
    file_name = params["name"]
    send_file("#{Rails.root}/public/#{file_name}")
  end

  def index
    
  end
end

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # protect_from_forgery with: :exception

  def youtube_liked
    receipe = Receipe.create(content: {extract_and_send: {title: params["title"], url: params["url"]}})
    receipe.delay.extract_and_send
    render json: {message: "ok"}, status: 200
  end

  def index
    
  end
end

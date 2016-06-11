require 'nokogiri'
class Book < ActiveRecord::Base

  validates :goodreads_id, uniqueness: true
  belongs_to :user

  after_initialize :init

  def init
    self.content ||= {}
  end

  def set_downloaded(result)
    self.content[:book_found] = !!result
    self.save
  end

  def upload_to_drive
    response = RestClient.get "http://gen.lib.rus.ec/search.php?req=#{isbn}"
    doc = Nokogiri(response)
    # find Mobi first
    book_pref = ["mobi", "epub", "pdf"]
    found_book = false
    book_pref.each do |extension|
      rows = doc.at("tr:contains('#{extension}')")
      if rows.blank?

      else
        puts "found #{extension} of #{title}"
        # Bookifi link
        links = rows.at("a[href*='bookfi']")
        if links
          bookfi_response = RestClient.get links["href"]
          bookfi_doc = Nokogiri(bookfi_response)
          download_link = bookfi_doc.at("a[href*='bookfi.net/dl/']")["href"]
          file_name = title + ".#{extension}"
          `wget -O "#{file_name}" #{download_link} --header="Referer:#{links["href"]}"`
          file = user.upload_to_drive(file_name, file_name, "Books")
          self.content[:book_download_url] = file.api_file.web_content_link
          self.save
          found_book = true
        end
      end
    end
    set_downloaded(found_book)
  end
end
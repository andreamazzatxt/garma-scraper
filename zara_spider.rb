require 'kimurai'

class ZaraSpider < Kimurai::Base
  @name = "zara_spider"
  @engine = :mechanize
  @start_urls = []
  @config = {}

  def parse(response, url:, data: {})
  end
end

ZaraSpider.crawl!
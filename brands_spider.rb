require 'kimurai'

class BrandsSpider < Kimurai::Base
  USER_AGENTS = ["Chrome", "Firefox", "Safari", "Opera"]
  @name = "brands_spider"
  @engine = :selenium_chrome
  @start_urls = ['https://directory.goodonyou.eco/brand/h-and-m']
  @config = {
    user_agent: -> { USER_AGENTS.sample }
  }

  def parse(response, url:, data: {})


    save_to './data/brands.json', item, format: :pretty_json
  end
end

BrandsSpider.crawl!

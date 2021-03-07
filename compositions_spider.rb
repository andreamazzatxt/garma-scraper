require 'kimurai'

class CompositionsSpider < Kimurai::Base
  USER_AGENTS = ["Chrome", "Firefox", "Safari", "Opera"]
  @name = "compositions_spider"
  @engine = :selenium_chrome
  @start_urls = ['https://www.sustainyourstyle.org/en/fibers-eco-review']
  @config = {
    user_agent: -> { USER_AGENTS.sample }
  }

  def parse(response, url:, data: {})
    response.css('.intrinsic').css('a').each_with_index do |link, i|
      link = "https://www.sustainyourstyle.org#{link.attr('href')}"
      request_to :parse_fiber, url: link, data: { sustainable: i < 18 }
    end
  end

  def parse_fiber(response, url:, data: {})
    fiber = {}
    fiber[:is_sustainable] = data[:sustainable]
    fiber[:name] = response.css('main').css('h2').text
    p fiber[:description] = response.css('main')
                                    .css('#content')
                                    .css('.html-block').text
                                    .gsub(/(?<=[a-z])(?=[A-Z])/, ': ')
    save_to './data/fibers.json', fiber, format: :pretty_json
  end
end

CompositionsSpider.crawl!

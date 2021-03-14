require 'kimurai'
require_relative 'scraper_helpers'

class BrandsSpider < Kimurai::Base
  USER_AGENTS = ["Chrome", "Firefox", "Safari", "Opera"]
  BRANDS = %w[hm patagonia nike zara]
  @name = "brands_spider"
  @engine = :selenium_chrome
  # link to home page
  @start_urls = ['https://directory.goodonyou.eco/']
  @config = {
    user_agent: -> { USER_AGENTS.sample }
  }

  def parse(response, url:, data: {})
    sleep 10
    BRANDS.each do |brand|
      input = browser.find_field('search')
      input.fill_in with: brand
      sleep 5
      response = browser.current_response
      response.css('a').each do |link|
        link = link.attr('href')
        if !link.nil? && link.match?(/\/brand/)
          request_to :parse_product, url: "https://directory.goodonyou.eco#{link}"
        end
      end
    end
  end

  def parse_product(response, url:, data: {})
    item = {}
    item[:name] = response.css('.sc-fAjcbJ').text
    item[:rating] = get_rating(response)
    item[:subratings] = get_subratings(response)
    item[:description] = get_description(response)
    save_to './data/brands.json', item, format: :pretty_json
    puts "#{item[:name]} - Saved 🤟"
  end

  private

  def get_rating(response)
    rating = []
    response.css('.StyledBox-sc-13pk1d4-0').css('svg').each do |icon|
      style = icon.attr('style')
      next if style.nil?

      if icon.attr('style').include?('opacity:')
        rating << style.match(/opacity:\s*(.+);/)[1]
      end
    end
    rating.index('1') + 1
  end

  def get_subratings(response)
    raw = response.css('.StyledBox-sc-13pk1d4-0 .gagNGz').text
    {
      planet: raw.match(/Planet(\d+)/)[1],
      people: raw.match(/People(\d+)/)[1],
      animals: raw.match(/Animals(\d+)/)[1]
    }
  end

  def get_description(response)
    paragraphs = []
    response.css('p').each do |paragraph|
      paragraphs << paragraph.text.split('.')[1..nil].join('.')
    end
    paragraphs.reject! { |string| string.size.zero? }
    p paragraphs
    {
      planet: paragraphs[0],
      people: paragraphs[1],
      animals: paragraphs[2]
    }
  end

  def scroll_end
    # scroll and update response object
    browser.execute_script('window.scrollBy(0,document.body.scrollHeight)') and sleep 15
    browser.current_response
  end
end

BrandsSpider.crawl!

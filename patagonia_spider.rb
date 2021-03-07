require 'kimurai'
require_relative 'scraper_helpers'

class PatagoniaSpider < Kimurai::Base
  #Limit object scraped
  LIMIT = 1
  BRAND = 'PATAGONIA'
  @name = 'patagonia_spider'
  @engine = :selenium_chrome
  @start_urls = ['https://eu.patagonia.com/it/en/shop/mens']
  @config = {
    user_agent: -> { Helper::USER_AGENTS.sample }
  }

  def parse(response, url:, data: {})
    department = Helper.uniformize(url.match(/\/(\w+)$/)[1])
    response = load_all_products(response)
    response.css('.product-tile')[0..LIMIT].each do |product|
      next if product.css('a').attr('href').nil?
      next if product.css('a').attr('href').text.include? '/shop'

      link = product.css('a').attr('href').value
      request_to :parse_product, url: "https://eu.patagonia.com/#{link}", data: { dep: department }
    end
  end

  def parse_product(response, url:, data: {})
    item = {}
    # Scrape basic infos
    item[:brand] = BRAND
    item[:name] = get_name(response)
    item[:depatment] = data[:dep]
    trigger_specs_button and response = browser.current_response
    item[:article_type] = get_article_type(response)
    item[:article_number] = get_article_number(response)
    item[:composition] = get_composition(response)
    item[:img] = get_img_link(response)
    item[:supplier] = get_supplier_info(response)
    puts "✅  #{item[:name]} parsed "
    save_to './data/patagonia_items.json', item, format: :pretty_json
    puts "🥳  Item #{item[:name]} saved "
  end

  private
  #########
  # Get methods to parse each information
  #########

  def get_name(response)
    response.css('#product-title').text
  end

  def get_article_type(response)
    raw_type = get_name(response).split(' ').last.downcase
    Helper.uniformize(raw_type)
  end

  def get_article_number(response)
    response.css('.buy-config__title')
            .css('span').last.text
            .match(/No\.\s(\d+)/)[1]
  end

  def get_img_link(response)
    link = response.css('.card__image').css('img').attr('src').value
    link.gsub(/(\?sw\=\d{2}&sh\=\d{2})/, '?sw=1000&sh=1000')
  end

  def get_composition(response)
    compositions = response.css('.pdp__content-material')
                           .css('ul').css('li').first.text
                           .scan(/((?<percentage>\d{1,2})%\s*(?<fiber>\w+\s*\w*))/)
    compositions.map! do |composition|
      {
        percentage: composition[0].to_i,
        fiber: composition[1]
      }
    end
    Helper.reduce_composition(compositions)
  end

  def get_supplier_info(response)
    suppliers = []
    get_supplier_link(response).each do |link|
      supplier = make_supplier_object("https://eu.patagonia.com/#{link.attr('href')}")
      suppliers << supplier
    end
    suppliers
  end

  def make_supplier_object(link)
    puts "👺  LINK #{link}"
    browser.visit(link)
    response = browser.current_response
    sleep 5
    {
      "exist?": true,
      "name": response.css('.hero-main__headline').text.gsub(/\n/, ''),
      "country": response.css('.hero-main__subhead').text.match( /, (\w+)$/)[1],
      "address": response.css('.hero-main__subhead').text
    }
  end

  ######
  # Helpers methods to handle actions on the page
  ######

  def load_all_products(response)
    puts "😨 Loading Products..."
    count = response.css('.product-tile').count
    loop do
      trigger_load_button if response.css('.show-more').any?
      response = browser.current_response
      new_count = response.css('.product-tile').count
      break if count == new_count

      puts "💪 products loaded: #{new_count}"
      count = new_count
    end
    response
  end

  def trigger_load_button
    browser.execute_script("
       document.querySelector('.show-more').querySelector('button').click()
      ")
    sleep 2
  end

  def trigger_specs_button
    browser.execute_script("
       document.querySelector('.content__column-right').querySelector('a').click()
      ")
  end

  def get_supplier_link(response)
    response.css('.module__product-impact-slider')
            .css('.card--fpc-facility-content')
            .css('.card__link-full')
  end
end

PatagoniaSpider.crawl!

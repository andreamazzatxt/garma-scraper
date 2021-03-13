require 'kimurai'
require 'json'
require 'open-uri'
require_relative 'scraper_helpers'

class NikeSpider < Kimurai::Base
  # Limit pagination scrolling t n. number of pages
  # nil for infinity(scraper stops when there are no more new articles)
  BRAND = 'NIKE'.freeze
  LIMIT = 1
  USER_AGENTS = %w[Chrome Firefox Safari Opera].freeze
  @name = 'nike_spider'
  @engine = :selenium_chrome
  @start_urls = ['https://www.nike.com/gb/w/mens-clothing-6ymx6znik1',
                 'https://www.nike.com/gb/w/womens-clothing-5e1x6z6ymx6',
                 'https://www.nike.com/gb/w/womens-shoes-5e1x6zy7ok',
                 'https://www.nike.com/gb/w/mens-shoes-nik1zy7ok']
  @config = {
    user_agent: -> { USER_AGENTS.sample }
    # retry_request_errors: [{ error: NoMethodError, skip_on_failure: true }]
  }
  def parse(response, url:, data: {})
    response = pagination(response)
    department = Helper.uniformize(url.match(/\/([a-z]+)-/)[1])
    response.css('.product-card__img-link-overlay').each do |link|
      request_to :parse_product, url: link.attr('href'), data: { dep: department }
    end
  end

  def parse_product(response, url:, data: {})
    item = {}
    item[:brand] = BRAND
    item[:name] = get_name(response)
    item[:department] = data[:dep]
    item[:article_type] = get_article_type(response)
    item[:article_number] = get_article_number(response)
    item[:img] = get_img_url(response)
    item[:composition] = get_composition(response)
    check_suppliers
    item[:supplier] = get_supplier_info(response)

    save_to './data/nike_items.json', item, format: :pretty_json
  end

  private

  def get_article_number(response)
    response.css('.description-preview__features')
            .text.match(/Style:\s(.+)/)[1] ||
  end

  def get_name(response)
    response.css('#pdp_product_title').text
  end

  def get_img_url(response)
    response.css('li')
            .css('.selected')
            .css('img')[1]
            .attr('src')
  end

  def get_article_type(response)
    response.css('h2').text.split(' ').last
  end

  def get_composition(response)
    compositions = response.css('.pi-pdpmainbody')
                           .css('ul').text
                           .gsub(/(?<=[a-z])(?=[A-Z])/, '/')
                           .scan(/(?<group>(?<percentage>\d+)%\s(?<fiber>\w+\s*\w*))/)
    reduce_composition(compositions.map do |composition|
      {
        percentage: composition[1],
        fiber: composition[2]
      }
    end)
  end

  def get_supplier_info(_response)
    # Nike doesn't public the origin of each product
    # In alternative we give the number of suppliers for each country
    alternative = check_suppliers[0..2].map do |couple|
      { country: couple[0], number_factory: couple[1] }
    end
    {
      exist?: false,
      name: 'n/a',
      country: 'n/a',
      address: 'n/a',
      alternative: alternative
    }
  end

  def reduce_composition(array)
    count = 0
    new_array = []
    array.each do |composition|
      new_array << composition if count < 100
      count += composition[:percentage].to_i
    end
    new_array
  end

  def pagination(response)
    # Scroll page till end to load all content, it stops to LIMIT
    # If LIMIT is nil (infinite) scroll unitll new content is loaded
    count = response.css('.product-card__img-link-overlay').count
    (0..LIMIT).each do
      response = scroll_end_update_response
      new_count = response.css('.product-card__img-link-overlay').count
      break if count == new_count

      count = new_count
      logger.info "> Continue scrolling, current count is #{count}..."
    end
    logger.info "> Pagination is done.#{count} items found"
    response
  end

  def scroll_end_update_response
    # scroll and update response object
    browser.execute_script('window.scrollBy(0,document.body.scrollHeight)') and sleep 2
    browser.current_response
  end

  def check_suppliers
    suppliers = {}
    db = JSON.parse(open('./data/nike_factories.json').read)
    db.each do |supplier|
      c = supplier['country/region']
      suppliers.key?(c) ? suppliers[c] += 1 : suppliers[c] = 1
    end
    suppliers.sort_by { |_sup, number| number }.reverse
  end
end

NikeSpider.crawl!

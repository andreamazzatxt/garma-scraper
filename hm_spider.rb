require 'kimurai'
require_relative 'scraper_helpers'

class HmSpider < Kimurai::Base
  # Limit the N. of Articles Scraped per section (see start_urls)
  BRAND = 'HM'
  LIMIT = 5
  USER_AGENTS = ["Chrome", "Firefox", "Safari", "Opera"]
  @name = "hm_spider"
  @engine = :selenium_chrome
  # Put  link of a overview_pagewith grid of items
  @start_urls = ['https://www2.hm.com/en_gb/ladies/shop-by-product/view-all.html',
                 'https://www2.hm.com/en_gb/men/shop-by-product/view-all.html',
                 'https://www2.hm.com/en_gb/divided/shop-by-product/view-all.html',
                 'https://www2.hm.com/en_gb/baby/products/all.html',
                 'https://www2.hm.com/en_gb/kids/products/all.html']
  @config = {
    user_agent: -> { USER_AGENTS.sample }
  }

  def parse(response, url:, data: {})
    response.css('.product-item')[0..LIMIT].each do |product|
      link = product.css('a').attr('href')
      department = Helper.uniformize(url.match(/https:\/\/www2\.hm\.com\/[a-z]{2}_[a-z]{2}\/(\w+)/)[1])
      logger.info ">   🕵️    #{link}"
      request_to :parse_product, url: "https://www2.hm.com#{link}", data: { dep: department }
    end
    # Uncomment the following line to test one product (comment the rest of the method!)
    # request_to :parse_product, url: "https://www2.hm.com/en_gb/productpage.0962908001.html"
  end

  def parse_product(response, url:, data: {})
    item = {}
    # Scrape basic infos
    item[:brand] = BRAND
    item[:name] = get_name(response)
    item[:depatment] = data[:dep]
    item[:article_type] = get_article_type(response)
    item[:article_number] = get_article_number(response)
    item[:composition] = get_composition(response)
    item[:img] = get_img_link(response)
    # Opens Product Background Modal
    if browser.find_button('PRODUCT BACKGROUND').visible?
      browser.click_button('PRODUCT BACKGROUND')
      browser.click_button('Suppliers and factories for this product.')
    end
    # Re Assign response with the current one (with modal open)
    response = browser.current_response

    # Scrape Supplier Info
    item[:supplier] = get_supplier_info(response)
    save_to './data/hm_items.json', item, format: :pretty_json
  end

  private

  def get_name(response)
    response.css('.name-price').css('h1').text
            .gsub(/\n/, '')
            .gsub(/\t/, '')
            .gsub(/\s+/, ' ').strip
  end

  def get_article_type(response)
    response.css('.breadcrumbs-list').text
            .gsub(/\n/, '')
            .gsub(/\t/, '')
            .gsub(/\s+/, ' ')
            .split(' ')[2]
  end

  def get_article_number(response)
    response.css('.pdp-description-list').text
            .scan(/No\.(\d+)/)[0][0]
  end

  def get_composition(response)
    compositions = response.css('.product-details-details')
                           .css('.details-attributes-list-item').text
                           .gsub(/(?<=[a-z])(?=[A-Z])/, ' ')
                           .scan(/(\w+\s{1}\d+%)/).flatten
    compositions.map! do |composition|
      {
        percentage: composition.split(' ')[1].gsub('%', '').to_i,
        fiber: composition.split(' ')[0].downcase
      }
    Helper.reduce_composition(compositions)
    end
  end

  def get_img_link(response)
    img_link = response.css('.product-detail-main-image-container')
                       .css('img').attr('srcset').value.split(' ')[0]
    "https:#{img_link}"
  end

  def get_supplier_info(response)
    # some items doesn't have info about the supplier
    exist = response.css('#portal').any?
    {
      exist?: exist,
      name: exist ? response.css('#portal').css('article').css('h4').text : 'n/a',
      country: exist ? response.css('#portal').css('h3')[-1].text : 'n/a',
      address: exist ? response.css('#portal').css('article').css('address').text
                         : "#{BRAND} doesn't publish informations about suppliers of this item"
    }
  end
end
# https://www2.hm.com/en_gb/ladies/shop-by-product/view-all.html
HmSpider.crawl!

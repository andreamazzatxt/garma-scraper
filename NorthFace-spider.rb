require 'kimurai'

class NorthFaceDashSpider < Kimurai::Base


  BRAND = 'THE NORTH FACE'.freeze
  LIMIT = 10
  USER_AGENTS = %w[Chrome Firefox Safari Opera].freeze
  @name = "NorthFace-spider"
  @engine = :selenium_chrome
  @start_urls = ['https://www.thenorthface.co.uk/shop/en-gb/tnf-gb/men-jackets',
   'https://www.thenorthface.co.uk/shop/en-gb/tnf-gb/men-tops',
   'https://www.thenorthface.co.uk/shop/en-gb/tnf-gb/men-bottoms',
   'https://www.thenorthface.co.uk/shop/en-gb/tnf-gb/footwear-men',
   'https://www.thenorthface.co.uk/shop/en-gb/tnf-gb/women-jackets',
   'https://www.thenorthface.co.uk/shop/en-gb/tnf-gb/women-tops',
   'https://www.thenorthface.co.uk/shop/en-gb/tnf-gb/women-bottoms',
   'https://www.thenorthface.co.uk/shop/en-gb/tnf-gb/footwear-women',
   'https://www.thenorthface.co.uk/shop/en-gb/tnf-gb/kids-girls',
   'https://www.thenorthface.co.uk/shop/en-gb/tnf-gb/kids-boys',
   'https://www.thenorthface.co.uk/shop/en-gb/tnf-gb/kids-infants'
  ]
  @config = {
    user_agent: -> { USER_AGENTS.sample }
  }

  def parse(response, url:, data: {})
    response.css('.product-block .product-block-pdp-url').each do |link|

      request_to :parse_product, url: "https://www.thenorthface.co.uk".concat(link.attr('href')), data: { }
    end
  end

   def parse_product(response, url:, data: {})
    item = {}
    item[:brand] = BRAND
    item[:name] = get_name(response)
    item[:department] = get_department(response)
    item[:article_type] = get_article_type(response)
    item[:article_number] = get_article_number(response)
    item[:img] = get_img_url(response)
    item[:composition] = get_composition(response)
    # check_suppliers
    item[:supplier] = ' 😔 The North Face does not show supplier info for this product'

    save_to './data/north_face_items.json', item, format: :pretty_json
  end

  def get_name(response)
    response.css('.product-content-info-name').text
  end

  def get_department(response)
    response.css('.breadcrumbs').css('li')[2].text.gsub('\n', '').gsub('\t' , '').strip
  end


  def get_article_type(response)
    response.css('.current').text.gsub('\n', '').gsub('\t', '').strip
  end

  def get_article_number(response)
    response.css('#overlay-unique-id-image')[0]
            .attr('data-preview-image-uri').match(/\/(........)_/).to_s
            .gsub('/', '')
            .gsub('_', '')

    # resp = response.css('.pdp-specifications-list').css('dd')[0].text
    # skip_on_failure if resp.nil?
  end

   def get_img_url(response)
    response.css('#overlay-unique-id-image')[0]
            .attr('data-preview-image-uri')
  end

  def get_composition(response)
    compositions = response.css('.pdp-specifications-list-value').text
                           .scan(/(?<group>(?<percentage>(\d+\.\d+)|(\d+))%\s(?<fiber>\w+\s*\w*))/)

    reduce_composition(compositions.map do |composition|
      {
        percentage: composition[1].to_f,
        fiber: composition[2]
      }
    end)
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

end

NorthFaceDashSpider.crawl!

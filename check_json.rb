require 'json'

def check_json
  items = JSON.parse(open('./data/north_face_items.json').read)
  fabrics = JSON.parse(open('./data/fibers.json').read)
  fabrics.map! { |fabric| fabric['name'].downcase }
  not_included = []
  items.each do |item|
    item['composition'].each do |fabric|
      unless fabrics.include?(fabric['fiber'].downcase)
        not_included << fabric['fiber']
      end
    end
  end
  p not_included.uniq
end


check_json()

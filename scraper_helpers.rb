require 'active_support/inflector'

class Helper
  USER_AGENTS = %w[Chrome Firefox Safari Opera].freeze
  WOMAN = %w[lady].freeze
  MEN = %w[divided].freeze
  SWEATSHIRT = %[hoody].freeze
  def self.uniformize(word)
    word = word.singularize.singularize
    word = 'woman' if WOMAN.include? word
    word = 'young' if MEN.include? word
    word = 'sweathirt' if SWEATSHIRT.include? word
    word
  end

  def self.reduce_composition(array)
    count = 0
    new_array = []
    array.each do |composition|
      new_array << composition if count < 100
      count += composition[:percentage].to_i
    end
    new_array
  end
end

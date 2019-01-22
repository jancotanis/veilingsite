require 'open-uri'
require 'json'

#fields
# Kavel #	Inbreng #	Kunstenaar	Link	Soort	Jaartal	Titel	Prijs	Verhaaltje
LOT_NR = "Kavel #"
CONTRIBUTION_NR = "Inbreng #"
TITLE = "Titel"
ARTIST = "Kunstenaar"
LINK = "Link"
PRICE = "Prijs"
CATEGORY = "Soort"
TEXT = "Text"
YEAR = "Jaartal"
DESCRIPTION = "Verhaaltje"


# Tab Seperated Values
class TSV
  attr_reader :filepath
  def initialize(filepath)
    @filepath = filepath
  end

  def parse
    open(filepath) do |f|
      headers = f.gets.strip.split("\t")
      f.each do |line|
        fields = Hash[headers.zip(line.chop.split("\t"))]
        yield fields
      end
    end
  end
end

class Record
	def initialize( j )
		@j = j
	end

	def hash
		@j
	end

	def json
		hash.to_json
	end
end

class Photo < Record
	def initialize( file )
		@file = file
		super( { :file=>file} )
	end
end

class Lot < Record
	attr_reader :lot, :contribution, :artist, :link, :title, :year, :price, :text, :photos, :category
	def initialize lot, contribution, artist, link, title, category, year, price, text, photos=[]
		@lot = lot
		@contribution = contribution
		@artist = artist
		@link = link
		@title = title
		@category=category
		@year = year
		@price = price
		@text = text
		@photos = photos
		super( {
		:lot => lot,
		:contribution => contribution,
		:artist => artist,
		:link=>link,
		:title => title,
		:year => year,
		:price => price,
		:text => text,
		:photos => photos
		} )
	end

	def id
		"#{@artist}-#{@title}.html"
	end
	
	def add_photo file
		@photos << file
	end

end


class LotParser
	attr_reader :lots, :categories

	def initialize( path, file )
		tsv = TSV.new( "#{path}#{file}" ) 
		@lots = []
		@categories = Hash.new { |hash, key| hash[key] = [] }
		# fields:
		tsv.parse do |row|
			begin
				
				if  row[CONTRIBUTION_NR]
					photos = find_photos( path, row[CONTRIBUTION_NR] )
					lot = Lot.new( row[LOT_NR], row[CONTRIBUTION_NR], row[ARTIST], row[LINK], row[TITLE], row[CATEGORY], row[YEAR], row[PRICE], row[DESCRIPTION], photos )
					@lots << lot
					@categories[row[CATEGORY]] << lot
				end
			rescue
				puts row
				raise
			end
		end
	end
	
	def stats
		puts "-" * 50
		puts "#{@lots.count} lots found in #{@categories.count} categories"
		puts " Categories are: #{@categories.keys}"
		puts "-" * 50
	end

	private
	def find_photos path="./", id
		Dir["#{path}#{id}-*.*"]
	end
	
end


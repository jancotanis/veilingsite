require 'open-uri'
require 'json'

#fields
# Kavel #	Inbreng #	Kunstenaar	Link	Soort	Jaartal	Titel	Prijs	Verhaaltje
LOT_NR = "Kavel #"
CONTRIBUTION_NR = "Inbreng #"
TITLE = "Titel"
ARTIST = "Kunstenaar"
LINK = "Link"
PRICE = "Prijs €"
CATEGORY = "Soort"
YEAR = "Jaartal"
DESCRIPTION = "Tekst + link"

MISSING_PHOTO = "./assets/coming-soon.jpg"

# set default encoding and do an encode on the input file from excel to get correct extended characters
#Encoding.default_external = Encoding::UTF_8
#Encoding.default_internal = Encoding::UTF_8
# Tab Seperated Values
class TSV
  attr_reader :filepath
  def initialize(filepath)
    @filepath = filepath
  end

  def parse
  #,"r:cp850"
    File::open( filepath, "r" ) do |f|
      headers = f.gets.encode("UTF-8", "Windows-1252").strip.split("\t")
      f.each do |line|
        fields = Hash[headers.zip(line.encode("UTF-8", "Windows-1252").chop.split("\t"))]
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

class Lot < Record
	attr_reader :lot, :contribution, :artist, :link, :title, :year, :price, :text, :photos, :category
	def initialize lot, contribution, artist, link, title, category, year, price, text, photos=[]
	
		title = "?" if title.empty?
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
				if row[ARTIST] && !row[CONTRIBUTION_NR].empty?
					photos = find_photos( path, row[CONTRIBUTION_NR] )
					lot = Lot.new( row[LOT_NR], row[CONTRIBUTION_NR], row[ARTIST], row[LINK], row[TITLE], row[CATEGORY], row[YEAR], row[PRICE], row[DESCRIPTION], photos )
					puts lot.json
					@lots << lot
					cat = row[CATEGORY]
					cat = "onbekend" if cat.empty?
					@categories[cat] << lot
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
		photos = Dir["#{path}#{id}-*.*"]
		photos = [MISSING_PHOTO] if photos.count == 0
		return photos
	end
	
end

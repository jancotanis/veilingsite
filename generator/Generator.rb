
require 'erb'
require './Lot.rb'

ROOT = "./data/"


Page = Struct.new(:prev,:next)

class SiteGenerator
	attr_reader :categories

	def initialize( db, template_dir, site_dir )
		@db = db
		@dir = template_dir
		@site = site_dir
		@categories = @db.categories
	end

	def generate_index
		file = "index.html"
		t = load_template "#{file}.erb"
		puts " File: #{file}"
		File::open( "#{@site}#{file}", "w" ) do |f|
			f.write t.result( binding )
		end
	end

	def generate_categories
		t = load_template "category.html.erb"
		@categories.each do |category, lots|
			file = sanitize_filename( "#{category}.html" )
			puts " Category: #{file}"
			File::open( "#{@site}#{file}", "w" ) do |f|
				f.write t.result( binding )
			end
		end
	end

	def generate_lots
		t = load_template "lot.html.erb"
		page = Page.new( "/", "/" )

		@db.lots.each_with_index do |lot, i|
			page.next = (i+1 < @db.lots.count) ? sanitize_filename( @db.lots[i+1].id ) : "/"
			file = sanitize_filename lot.id
			puts " Lot: #{file}"
			File::open( "#{@site}#{file}", "w" ) do |f|
				f.write t.result( binding )
			end
			page.prev = file
		end
	end

	def render file
		t = load_template file
		t.result( binding )
	end

private
	def load_template file
		ERB.new( File.read( File.expand_path( "#{@dir}#{file}" ) ) )
	end
	
	def sanitize_filename(filename)
		name = filename.strip
		# NOTE: File.basename doesn't work right with Windows paths on Unix
		# get only the filename, not the whole path
		name.gsub!( /^.*(\\|\/)/, '' )

		# Strip out the non-ascii character
		name.gsub!( /[^0-9A-Za-z.\-]/, '-' )
		name
	end
end


db = LotParser.new( "#{ROOT}", "Kunstveiling-veilinginput.txt" )
db.stats
sg = SiteGenerator.new( db, "./templates/", "../site/" )
# index.html
sg.generate_index
# voorwaarden.html
# sponsors.html
# all lots
sg.generate_lots
# all categories
sg.generate_categories

#    Book     = Struct.new(:title, :author#)
#    template = ERB.new(File.read('template.erb'))
#    template.result_with_hash(books: [Book.new("test"), Book.new("abc")])

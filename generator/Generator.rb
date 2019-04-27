
require 'erb'
require './Lot.rb'

Page = Struct.new(:title,:include)

class SiteGenerator
	attr_reader :categories

	def initialize( db, template_dir, site_dir )
		@db = db
		@dir = template_dir
		@site = site_dir
		@categories = @db.categories
		@pageinfo = nil
	end

	def generate_index
		file = "index.html"
		@pageinfo = Page.new( "Lions Club", file )
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
			@pageinfo = Page.new( category, file )
			puts " Category: #{file}"
			File::open( "#{@site}#{file}", "w" ) do |f|
				f.write t.result( binding )
			end
		end
	end
	def generate_kavels
		t = load_template "kavels.html.erb"
		lots = []
		@db.lots.each do |l|
			if l.lot
				if lots[l.lot.to_i]
					puts "* Lot [#{l.lot}] is dubbel"
					puts "  " + l.id
					puts "  " + lots[l.lot.to_i].id
				else
					lots[l.lot.to_i] = l if l.lot
				end
			end
		end
		lots.compact!
		file = "kavels.html"
		@pageinfo = Page.new( "Kavels", file )
		puts " Kavels: #{file}"
		File::open( "#{@site}#{file}", "w" ) do |f|
			f.write t.result( binding )
		end
	end
#(http|ftp|https)://([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:/~+#-]*[\w@?^=%&/~+#-])?
	def generate_lots
		t = load_template "lot.html.erb"
		@db.lots.each_with_index do |lot, i|
			file = sanitize_filename lot.id
			@pageinfo = Page.new( lot.title, file )
			puts " Lot: #{file}"
			file( "#{@site}#{file}" ) do |f|
				f.write t.result( binding )
			end
			# copy assets
			lot.photos.each do |photo|
				if !File.exists? @site+photo
					puts "Copy #{photo} to #{@site+photo}"
					File.binwrite( @site+photo, File.binread( photo ) )
				end
			end
		end
	end

	def generate_static pages
		t = load_template "static-page.html.erb"
		pages.each do |p|
			@pageinfo = Page.new( p.capitalize, "static-#{p}.html" )
			file = "#{p}.html"
			puts " Page: #{file}"
			File::open( "#{@site}#{file}", "w" ) do |f|
				f.write t.result( binding )
			end
		end
	end

	def render file
		t = load_template file
		t.result( binding )
	end
	
	def auto_link text
       if text
		   pattern = /(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/
		   text.gsub( pattern ) do |url| 
	    	  url = "https://" + url unless url["http"]
		      "<a href='#{url}'>#{url}</a>"
		   end
	   else
	     ""
	   end
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

private

	def file name, &block
		File::open( name, "w" ) do |f|
			block.call( f )
		end
	end

	def load_template file
		file = "#{@dir}#{file}" unless File.exists?( file )
		ERB.new( File.read( File.expand_path( file ) ) )
	end
	
end

# defaults
assets_dir = "./assets/"
db_name = "Kunstveiling-veilinginput.txt"
template_dir = "./templates/"
site_dir = "../"
# override fromthe command line
assets_dir = ARGV[0] if ARGV.count > 0
db_name = ARGV[1] if ARGV.count > 1
template_dir = ARGV[2] if ARGV.count > 2
site_dir = ARGV[3] if ARGV.count > 3

puts "SiteGenerator [assets] [db] [templates] [site]"
db = LotParser.new( assets_dir, db_name )
db.stats
sg = SiteGenerator.new( db, template_dir, site_dir )
# index.html
sg.generate_index
# voorwaarden.html
sg.generate_static ["voorwaarden","about","doel","contact","sponsor"]
# all categories
sg.generate_categories
sg.generate_kavels
# all lots
sg.generate_lots

require 'csv'
require 'net/http'
require 'rexml/document'
require 'tmpdir'

def fetch(tmpdir)
	users_file 	= "users.txt"
	usernames 	= []

	File.open(users_file).each_line do |line|
		usernames << line.strip
	end

	usernames.each do |username|
		puts username

		command = "wget --output-document #{tmpdir}/#{username} http://www.boardgamegeek.com/xmlapi/collection/#{username}?own=1"
		puts command
		`#{command}`
	end
end

def generateCSV(tmpdir)
	usernames 			= Dir.entries(tmpdir) - ['.', '..']
	user_collections 	= {} # key: username, value: titles hash
	all_titles 			= {} #key: game id, value: game name
	game_freq 			= {} # key: gamed id, value: ownership frequency
	game_freq.default 	= 0

	usernames.each do |username|
		doc_name 	= "#{tmpdir}/#{username}"
		xml_data 	= File.open(doc_name, 'rb').read
		doc 		= REXML::Document.new(xml_data)
		titles 		= {}  # key: game id, value: game name

		doc.elements.each('items/item') do |element|
			titles[element.attributes["objectid"]] = element.elements['name'].text
		end

		user_collections[username] = titles
		all_titles = all_titles.merge(titles)
		puts titles.length
	end

	# Export user-games matrix
	output_file = "results/results-" + Time.now.to_i.to_s + ".csv"

	CSV.open(output_file, 'wb') do |csv|
		csv << [""] + all_titles.values

		usernames.each do |username|
			row = [username]
			all_titles.each do |id, name|
				if user_collections[username][id]
					row << 'X'
	        		game_freq[id] += 1
				else
					row << ''
				end
			end

			csv << row
		end

		csv << []	
		csv << ["Total"] + game_freq.values
	end
	puts "Results written to " + output_file
end

tmpdir = Dir.mktmpdir
fetch(tmpdir)
generateCSV(tmpdir)
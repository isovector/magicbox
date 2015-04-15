require 'csv'
require 'net/http'
require 'rexml/document'
require 'tmpdir'

def fetch(tmpdir)
    usernames   = []

    ARGF.readlines.each do |line|
        usernames << line.strip
    end

    puts "Fetching #{usernames.length} user collections to #{tmpdir}:"

    return usernames
end

class EmptyFileException < RuntimeError
end

def generateCSV(tmpdir, usernames)
    user_collections    = {} # key: username, value: titles hash
    all_titles          = {} # key: game id, value: game name
    game_freq           = {} # key: gamed id, value: ownership frequency
    game_freq.default   = 0
    last_failed_user = nil
    try_again = false

    puts "Analyzing the collections:"
        usernames.each do |username|
        begin
            puts username
            sleep(0.5)
            command = "curl --silent --output '#{tmpdir}/#{username}' http://www.boardgamegeek.com/xmlapi/collection/#{URI.escape(username)}?own=1"
            `#{command}`

            doc_name    = "#{tmpdir}/#{username}"
            xml_data    = File.open(doc_name, 'rb').read
            doc             = REXML::Document.new(xml_data)
            titles      = {}  # key: game id, value: game name

            doc.elements.each('items/item') do |element|
                titles[element.attributes["objectid"]] = element.elements['name'].text
            end

            user_collections[username] = titles
            all_titles = all_titles.merge(titles)
            raise EmptyFileException if titles.length == 0

        rescue
            if (last_failed_user != username) && (last_failed_user != nil)
                puts "*\tRetrying..."
                sleep(2)
                last_failed_user = username
                retry
            end

            last_failed_user = username

            puts "\nNo titles found for #{username}. Here's what was downloaded\n\n"
            puts xml_data
            puts
            puts "Press 'enter' to retry downloading the collection. Press 'c' then 'enter' to continue.\n"

            if gets.strip.downcase == "c"
                next
            else
                retry
            end
        end
    end

    # Export user-games matrix
    output_file = "results/" + Time.now.to_i.to_s + ".csv"

    CSV.open(output_file, 'wb') do |csv|
        csv << ["username"] + all_titles.values

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

    puts
    puts "Results written to " + output_file
end

tmpdir = Dir.mktmpdir
usernames = fetch(tmpdir)
puts
generateCSV(tmpdir, usernames)

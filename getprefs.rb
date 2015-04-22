require 'csv'
require 'net/http'
require 'rexml/document'
require 'tmpdir'

users = CSV.table(ARGV[0])
reqs = users[:username].zip(users[:email]).map { |r|
    "requests=" + r.join(":")
}.join("&")
`curl --silent -L -G -d '#{reqs}' --output prefs.csv http://52.10.229.25/api/preferences`


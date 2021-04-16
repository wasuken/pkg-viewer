# coding: utf-8
require 'csv'
require 'sequel'

# DB = Sequel.connect('sqlite://pkg.sqlite3')

DB = Sequel.mysql2(
  host: ENV['DB_HOST'],
  user: ENV['DB_USER'],
  password: ENV['DB_PASS'],
  database: ENV['DB_NAME'],
)

recs = []

CSV.foreach(ARGV[0], headers: true, encoding: "iso-8859-1:UTF-8").each do |fg|
  recs << {
    name: fg['Name'],
    status: fg['Status'],
    description: fg['Description'],
    references: fg['References'],
    phase: fg['Phase'],
    votes: fg['Votes'],
    comments: fg['Comments']
  }
  if recs.size > 1000
    DB[:cves].multi_insert(recs)
    recs = []
  end
end

if recs.size > 0
  DB[:cves].multi_insert(recs)
end

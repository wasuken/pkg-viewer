# coding: utf-8
require 'csv'
require 'sequel'

DB = Sequel.connect('sqlite://pkg.sqlite3')

recs = []

CSV.foreach(ARGV[0], headers: true, encoding: "iso-8859-1:UTF-8") do |fg|
  recs << {
    name: fg['name'],
    status: fg['status'],
    description: fg['description'],
    references: fg['references'],
    phase: fg['phase'],
    votes: fg['votes'],
    comments: fg['comments']
  }
  if recs.size > 1000
    DB[:cves].multi_insert(recs)
    recs = []
  end
end

if recs.size > 0
  DB[:cves].multi_insert(recs)
end

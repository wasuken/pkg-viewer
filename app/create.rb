# coding: utf-8
require 'sequel'

# DB = Sequel.sqlite './pkg.sqlite3'

DB = Sequel.mysql2(
  host: ENV['DB_HOST'],
  user: ENV['DB_USER'],
  password: ENV['DB_PASS'],
  database: ENV['DB_NAME'],
)

DB.create_table :srvs do
  String :name, size: 255
  String :type, size: 255
  primary_key [:name]
end

DB.create_table :srv_pkgs do
  String :p_name, size: 255
  String :s_name, size: 255
  String :version, size: 255
  String :created_at, size: 255
  primary_key [:p_name, :s_name, :created_at]
end

DB.create_table :cves do
  String :name, size: 255
  String :status, size: 255
  String :description, text: true
  String :references, text: true
  String :phase, text: true
  String :votes, text: true
  String :comments, text: true
  primary_key [:name]
end

# coding: utf-8
require 'sequel'

DB = Sequel.sqlite './pkg.sqlite3'

DB.create_table :srvs do
  String :name
  String :type
  primary_key [:name]
end

DB.create_table :srv_pkgs do
  String :p_name
  String :s_name
  String :version
  String :created_at
  primary_key [:p_name, :s_name, :version, :created_at]
  index :s_name
  index :created_at
end

DB.create_table :cves do
  String :name
  String :status
  String :description
  String :references
  String :phase
  String :votes
  String :comments
  primary_key [:name]
end

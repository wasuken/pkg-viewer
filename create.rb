# coding: utf-8
require 'sequel'

DB = Sequel.sqlite './pkg.sqlite3'

DB.create_table :pkgs do
  String :name
  String :version
  primary_key [:name]
end

DB.create_table :srvs do
  String :name
  String :type
  primary_key [:name]
end

DB.create_table :srv_pkgs do
  String :p_name
  String :s_name
  String :created_at
  primary_key [:p_name, :s_name]
end

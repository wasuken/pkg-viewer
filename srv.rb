require 'sinatra'
require 'haml'
require 'sequel'

set :bind, '0.0.0.0'
DB = Sequel.connect('sqlite://pkg.sqlite3')

get '/' do
  @pkg_names = DB[:pkgs].to_a.map{ |x| x[:name].split('/')[0]}.uniq.sort
  @srv_names = DB[:srvs].to_a.map{ |x| x[:name]}.sort
  latest = DB[:srv_pkgs].max(:created_at)

  pkgs = DB[:srv_pkgs]
           .join(:srvs, name: :s_name)
           .join(:pkgs, Sequel[:pkgs][:name] => Sequel[:srv_pkgs][:p_name])
           .where(created_at: latest)

  @pkg_tbl = {}
  @srv_names.each do |s_name|
    pkgs.where(s_name: s_name).to_a.each do |p|
      @pkg_tbl[s_name] = {  } unless @pkg_tbl[s_name]
      p_name = p[:name].split('/')[0]
      @pkg_tbl[s_name][p_name] = p[:version]
    end
  end

  haml :index
end

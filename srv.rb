# coding: utf-8
require 'sinatra'
require 'haml'
require 'sequel'
require 'json'

set :bind, '0.0.0.0'
DB = Sequel.connect('sqlite://pkg.sqlite3')

def cve(year)
  DB[:cves].where(Sequel.like(:name, "CVE-#{year}%"))
end

def gen_pkg_tbl(srv_names)
  latest = DB[:srv_pkgs].max(:created_at)

  pkgs = DB[:srv_pkgs]
           .join(:srvs, name: :s_name)
           .join(:pkgs, Sequel[:pkgs][:name] => Sequel[:srv_pkgs][:p_name])
           .where(created_at: latest)
  pkg_tbl = {}
  srv_names.each do |s_name|
    pkgs.where(s_name: s_name).to_a.each do |p|
      pkg_tbl[s_name] = {  } unless pkg_tbl[s_name]
      p_name = p[:name].split('/')[0]
      pkg_tbl[s_name][p_name] = p[:version]
    end
  end
  pkg_tbl
end

pkg_tbl_cache = {
  cache: true,
  data: gen_pkg_tbl(DB[:srvs].to_a.map{ |x| x[:name]}.sort)
}

get '/cve' do
  @pname = params[:pname]
  return unless @pname

  @cves = cve('202').where(Sequel.like(:description, "%#{@pname}%"))
  haml :cve
end

get '/api/v0/pkgs' do
  page = (params[:page] || "0").to_i
  offset = (params[:offset] || "30").to_i
  cache = params[:cache] || true
  query = params[:query] || ''

  # check
  page = 0 if page < 0
  offset = 30 if offset <= 0

  pkg_names = DB[:pkgs].to_a.map{ |x| x[:name].split('/')[0]}.uniq
  pkg_names = pkg_names.select{ |p| p =~ (Regexp.new query) } unless query.empty?
  max_page = (pkg_names.size / offset).ceil

  page = max_page if page > max_page

  cur = page*offset
  pkg_names = pkg_names.sort[cur...cur+offset]
  pkg_names = [] unless pkg_names

  srv_names = DB[:srvs].to_a.map{ |x| x[:name]}.sort

  if(cache && pkg_tbl_cache[:cache])
    puts "use cache"
    pkg_tbl = pkg_tbl_cache[:data]
  else
    pkg_tbl = gen_pkg_tbl(srv_names)
    pkg_tbl_cache[:data] = pkg_tbl
    pkg_tbl_cache[:cache] = true
  end
  resp = {
    data: pkg_tbl,
    pkg_names: pkg_names,
    srv_names: srv_names,
    status: 200,
    msg: '',
    offset: offset,
    page: page,
    query: query,
    cache: cache,
    max_page: max_page,
  }
  content_type :json
  response.body = JSON.dump(resp)
end

get '/' do
  haml :index
end

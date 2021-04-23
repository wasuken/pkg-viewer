# coding: utf-8
require 'sinatra'
require 'sinatra/reloader'
require 'haml'
require 'sequel'
require 'json'
require 'benchmark'

configure do
  set :bind, '0.0.0.0'
  register Sinatra::Reloader
  also_reload "models/**/*"
  also_reload "helpers/**/*"
end

DB = Sequel.mysql2(
  host: ENV['DB_HOST'],
  user: ENV['DB_USER'],
  password: ENV['DB_PASS'],
  database: ENV['DB_NAME'],
)

def cve(year)
  DB[:cves].where(Sequel.like(:name, "CVE-#{year}%"))
end

def gen_pkg_names
  DB[:srv_pkgs].to_a.map{ |x| { name: x[:p_name].split('/')[0], fullname: x[:p_name] }}.uniq
end

def gen_pkg_tbl(srv_names, pkgs)
  pkg_tbl = {}
  srv_names.each do |s|
    pkg_tbl[s] = {  }
  end
  pkgs.each do |p|
    s_name = p[:s_name]
    p_name = p[:p_name].split('/')[0]
    pkg_tbl[s_name][p_name] = p[:version]
  end
  pkg_tbl
end

pkgs = DB[:srv_pkgs]
         .where(created_at: DB[:srv_pkgs].max(:created_at))
         .to_a

pkg_tbl_cache = {
  cache: true,
  data: gen_pkg_tbl(DB[:srvs].to_a.map{ |x| x[:name]}.sort, pkgs),
  pkg_names: gen_pkg_names(),
  pkgs: pkgs
}

pkgs = nil

get '/cve' do
  @pname = params[:pname]
  return unless @pname

  @cves = cve('202').where(Sequel.like(:description, "%#{@pname}%")).limit(10)
  haml :cve
end

get '/api/v0/cves' do
  content_type :json
  name = params[:name]
  p params[:name]
  resp = {
    status: 200,
    msg: ''
  }
  if name.nil?
    resp[:status] = 400
    resp[:msg] = 'Invalid parameter[name]'
    response.body = JSON.dump(resp)
  else
    resp[:data] =
      cve('202')
        .where(Sequel.like(:description, "%#{name}%"))
        .order(Sequel.desc(:name))
        .limit(10)
        .to_a

    response.body = JSON.dump(resp)
  end
end

get '/api/v0/pkgs' do
  page = (params[:page] || "0").to_i
  offset = (params[:offset] || "30").to_i
  cache = params[:cache] || true
  query = params[:query] || ''

  # check
  page = 0 if page < 0
  offset = 30 if offset <= 0

  # pkg_names = DB[:srv_pkgs].to_a.map{ |x| x[:p_name].split('/')[0]}.uniq
  pkg_names = pkg_tbl_cache[:pkg_names]

  pkg_names = pkg_names.select{ |p| p[:name] =~ (Regexp.new query) } unless query.empty?

  max_page = (pkg_names.size / offset).ceil

  page = max_page if page > max_page

  cur = page*offset
  pkg_names = pkg_names.sort{ |a,b| a[:name] <=> b[:name] }[cur...cur+offset]
  pkg_names_short = pkg_names.map{ |x| x[:name]}
  pkg_names_short = [] unless pkg_names_short

  srv_names = DB[:srvs].to_a.map{ |x| x[:name]}.sort

  # if(cache && query.empty? && pkg_tbl_cache[:cache])
  #   puts "use cache"
  #   pkg_tbl = pkg_tbl_cache[:data]
  # else

  #   # pkg_tbl_cache[:data] = pkg_tbl
  #   # pkg_tbl_cache[:cache] = true
  # end
  pkgs = DB[:srv_pkgs]
           .where(created_at: DB[:srv_pkgs].max(:created_at))
           .where(p_name: pkg_names.map{ |x| x[:fullname]})
           .to_a
  pkg_tbl = gen_pkg_tbl(srv_names, pkgs)
  resp = {
    data: pkg_tbl,
    pkg_names: pkg_names_short,
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

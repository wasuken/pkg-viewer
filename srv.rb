require 'sinatra'
require 'haml'
require 'sequel'
require 'benchmark'

set :bind, '0.0.0.0'
DB = Sequel.connect('sqlite://pkg.sqlite3')

def cve(year)
  DB[:cves].where(Sequel.like(:name, "CVE-#{year}%"))
end

pkg_tbl_cache = {  }

get '/cve' do
  @pname = params[:pname]
  return unless @pname

  @cves = cve('202').where(Sequel.like(:description, "%#{@pname}%"))
  haml :cve
end

get '/' do
  @page = (params[:page] || "0").to_i
  offset = (params[:offset] || "30").to_i
  cache = params[:cache]
  cur = @page*offset
  @pkg_names = DB[:pkgs].to_a.map{ |x| x[:name].split('/')[0]}.uniq.sort
  @max_page = (@pkg_names.size / offset).ceil
  @pkg_names = @pkg_names[cur..cur+offset]

  @srv_names = DB[:srvs].to_a.map{ |x| x[:name]}.sort
  latest = DB[:srv_pkgs].max(:created_at)

  pkgs = DB[:srv_pkgs]
           .join(:srvs, name: :s_name)
           .join(:pkgs, Sequel[:pkgs][:name] => Sequel[:srv_pkgs][:p_name])
           .where(created_at: latest)

  if(cache && pkg_tbl_cache)
    @pkg_tbl = pkg_tbl_cache
  else
    @pkg_tbl = {}
    @srv_names.each do |s_name|
      pkgs.where(s_name: s_name).to_a.each do |p|
        @pkg_tbl[s_name] = {  } unless @pkg_tbl[s_name]
        p_name = p[:name].split('/')[0]
        @pkg_tbl[s_name][p_name] = p[:version]
      end
    end
  end
  cv = cve('202')
  @pkg_names.each do |p|
    @pkg_tbl[p] = {  } unless @pkg_tbl[p]
    @pkg_tbl[p]['cves'] = cv.where(Sequel.like(:description, "%#{p}%"))
  end

  haml :index
end

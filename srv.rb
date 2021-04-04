require 'sinatra'
require 'haml'
require 'sequel'

set :bind, '0.0.0.0'
DB = Sequel.connect('sqlite://pkg.sqlite3')

get '/' do
  @pkgs = DB[:srvs]
           .join_table(:inner, :srv_pkgs, name: :s_name)
           .join_table(:inner, :pkgs, p_name: :name)

  haml :index
end

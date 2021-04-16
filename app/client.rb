require 'net/ssh'
require 'json'
require 'sequel'
require 'set'

# DB = Sequel.connect('sqlite://pkg.sqlite3')

DB = Sequel.mysql2(
  host: ENV['DB_HOST'],
  user: ENV['DB_USER'],
  password: ENV['DB_PASS'],
  database: ENV['DB_NAME'],
)

hosts = JSON.parse(File.read('./config.json'))['hosts']

dt = Time.now.strftime('%Y/%m/%d %H:%M:%S')

hosts.each do |info|
  Net::SSH.start(info['host'], info['user'],
                 password: info['ps'],
                 keys:  [ "~/.ssh/id_rsa.pub" ],
                 host_key: "ssh-rsa"
                 # verbose: :debug
                ) do |ssh|
    p_s_params = []
    puts "connect: #{info['host']}"
    DB.execute("insert into srvs(name, type) select '#{info['host']}','apt' where not exists(select 1 from srvs where name = '#{info['host']}')")
    rst = ssh.exec!('apt list')
    lines = rst.split("\n")
    puts "parsing..."
    lines.each do |line|
      sp = line.split(' ')
      next if sp.size < 3 || sp.size > 4
      name, version = sp
      p_s_params << { p_name: name, s_name: info['host'], version: version, created_at: dt }
    end
    puts "inserting..."
    DB[:srv_pkgs].multi_insert(p_s_params)
    puts "end."
  end
end

require 'facter'
require 'json'
require 'net/http'

hostname = Facter.value('fqdn')
host = 'foreman'
port = '8001'
http = Net::HTTP.new(host, port)
http.read_timeout = 60
uri = "/api/v2/hosts/#{hostname}"

begin
  foreman_resp = JSON.load(http.get(uri).body) or {}
rescue
  foreman_resp = {}
end
if !foreman_resp.has_key?('parameters')
    false
else
  tags = foreman_resp['parameters']
  if
    tags.each do |tag|
     fact = "tag_#{tag['name']}"
     Facter.add(fact) { setcode { tag['value'] } }
    end
  end
end

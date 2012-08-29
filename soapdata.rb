require 'nokogiri'
require 'pry'
require 'net/http'
require 'net/https'
require 'JSON'
require 'hpricot'
require 'sanitize'

def get3dproduct count, start
# Create the http object
http = Net::HTTP.new('api.3dcart.com', 80)
http.use_ssl = false
path = '/cart.asmx'

# Create the SOAP Envelope
data = <<-EOF
<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xmlns:xsd="http://www.w3.org/2001/XMLSchema"
xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
<soap12:Body>
    <getProduct xmlns="http://3dcart.com/">
    <storeUrl>www.mobility-aids.com</storeUrl>
    <userKey>37906063633500222379060636335002</userKey>
    <batchSize>#{count}</batchSize>
    <startNum>#{start}</startNum>
    <productId></productId>
    <callBackURL></callBackURL>
    </getProduct>
</soap12:Body>
</soap12:Envelope>
EOF

# Set Headers
headers = {
  'Host' => 'api.3dcart.com',
  'Content-Type' => 'application/soap+xml; charset=utf-8',
  'Content-Length' => "#{data.length}"
}

http.post(path, data, headers)
end


# now lets use the api
xmldata = []

saftey = 2000
slevel = 0
while slevel < saftey
    resp, data = get3dproduct 1, slevel
    if Hpricot.XML(resp.body).search("Id").inner_html == "46" ||
      Hpricot.XML(resp.body).search("Description").inner_html == "No Data Found"
        slevel = saftey
    else
        slevel += 1
        xmldata.push resp.body
        put resp.body
    end
end

binding.pry

# Output the results
puts 'Code = ' + resp.code
puts 'Message = ' + resp.message
resp.each { |key, val| puts key + ' = ' + val }

pdata = Nokogiri::XML.parse(resp.body).css "Product"
puts pdata.display

binding.pry

mappings = JSON.parse File.open("sasmap.json").readline

def sasmap_3dcart prefix
    pre = prefix
    premap = {
        :WS => ["1","http://www.wrightstuff.biz"],
        :AS => ["2", "http://www.arthritissupplies.com"],
        :CG => ["3", "http://www.caregiverproducts.com"],
        :MA => ["4", "http://www.mobility-aids.com"]
    }
    puts "Using URL: #{premap[pre.to_sym].last} as root"

    if File.exists? "#{pre}-exceptions.log"
        FileUtils.rm "#{pre}-exceptions.log"
    end
    outp = "columns:\nnotforsale | stock | sku | name | categories\n"
    puts outp.encode!("cp1252")
    File.open("#{pre}-exceptions.log", "a+:cp1252") { |f| f << "#{outp}\n" }


end
    binding.pry

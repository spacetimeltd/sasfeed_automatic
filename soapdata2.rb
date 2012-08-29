require 'nokogiri'
require 'pry'
require 'net/http'
require 'net/https'

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
    <batchSize>1</batchSize>
    <startNum>1</startNum>
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

# Post the request
resp, data = http.post(path, data, headers)

# Output the results
puts 'Code = ' + resp.code
puts 'Message = ' + resp.message
resp.each { |key, val| puts key + ' = ' + val }

pdata = Nokogiri::XML.parse(resp.body).css "Product"
puts pdata.display

mappings = JSON.parse File.open("sasmap.json").readline



binding.pry


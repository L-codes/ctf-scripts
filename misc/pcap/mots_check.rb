#!/usr/bin/env ruby
#
# Author L
#

require 'oj'

pcap_file = ARGV[0]

abort "Usage: ./mots_check.rb <pcap_file>" unless pcap_file

json_data = `tshark -r '#{pcap_file}' -Y 'tcp.payload && tcp.flags == 0x18' -T json -e frame.number -e tcp.seq -e tcp.ack -e tcp.payload -e tcp.dstport -e tcp.srcport -e ip.src -e ip.dst`

mots = []
json = Oj.load(json_data).map{|x| x['_source']['layers'].transform_values(&:first) }
json.each_cons(2) do |i, j|
  ii = i.values_at('ip.src', 'ip.dst', 'tcp.srcport', 'tcp.dstport', 'tcp.seq', 'tcp.ack')
  jj = j.values_at('ip.src', 'ip.dst', 'tcp.srcport', 'tcp.dstport', 'tcp.seq', 'tcp.ack')
  if ii == jj && i['tcp.payload'] != j['tcp.payload']
    mots << i['frame.number'] << j['frame.number']
  end
end

if mots.empty?
  puts "No suspicious packets found"
else
  puts "Discover suspicious packets: #{mots.size / 2}"

  puts "wireshark display express:"
  puts "  frame.number in {#{mots.join(' ')}}"
end

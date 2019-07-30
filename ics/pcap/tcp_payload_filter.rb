#!/usr/bin/env ruby
# 
# Author L
#

pcap_file = ARGV[0]
display_filter = ARGV[1]
filter_regexp = ARGV[2]
filter_regexp = Regexp.new(filter_regexp) if filter_regexp

separator = "%6s #{'=' * 75}"

unless pcap_file && display_filter
  abort <<~EOF
  Usage: ./tcp_payload_filter.rb <pcap_file> <display_filter> [filter_regexp]
  EOF
end

`tshark -r #{pcap_file} -Y '#{display_filter}' -Tfields -e frame.number -e tcp.payload`.each_line do |line|
  num, hex_data = line.chomp.split("\t")
  raw = [hex_data].pack 'H*'

  if filter_regexp
    if raw.match?(filter_regexp)
      puts separator % num
      puts raw 
    end
  else
    puts separator % num
    puts raw
  end
end

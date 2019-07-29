#!/usr/bin/env ruby
# 
# Author L
#

require 'awesome_print'

filename = ARGV[0]
value_name = ARGV[1]

unless filename && value_name
  abort <<~EOF
  Usage: ./asn_to_hash.rb <file.asn> <value_name>
  EOF
end

data = File.read(filename).match(/#{value_name}\s+::=\s+CHOICE\s+{(.*?)}/m)

abort '[!] Not Find' unless data

hash = {}
data[1].each_line do |line|
  line.strip!
  next if line.start_with? '--'
  if line =~ /(.*?)\s+\[(.*?)\]/
    hash[$2] = $1
  end  
end

print "#{value_name} = "
ap hash

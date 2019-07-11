#!/usr/bin/env ruby
#
# Author L
# png_size_recover.rb image
#

require 'crc'

abort "Usage: ./png_size_recover.rb <png_file>" if ARGV.empty?

@png_file = ARGV[0]

data = File.binread(@png_file)

ihdr_head = data[12,4]
org_width = data[16,4]
org_high  = data[20,4]
ihdr_tail = data[24,5]
crc       = data[29,4]


def recover_file(i, data, name)
  if name == :width
    data[16,4] = [i].pack('i>')
  else
    data[20,4] = [i].pack('i>')
  end
  file = "recover_#{@png_file}"
  File.binwrite(file, data)
  puts "[+] recover #{name}: #{i}"
  puts "[+] save to: #{file}"
  exit()
end


65536.times.find do |i|
  ihdr = ihdr_head + [i].pack('i>') + org_high + ihdr_tail
  recover_file(i, data, :width) if CRC.crc32.digest(ihdr) == crc

  ihdr = ihdr_head + org_width + [i].pack('i>') + ihdr_tail
  recover_file(i, data, :high) if CRC.crc32.digest(ihdr) == crc
end

puts "[!] recover fail"

#!/usr/bin/env ruby
# 
# Author L
#

require 'oj'
require 'filesize'

pcap_file = ARGV[0]
extract_file = ARGV[1]

unless pcap_file
  abort <<~EOF
    Usage
      Read file list : ./mms_extract_file.rb <pcapfile>
      Extract file   : ./mms_extract_file.rb <pcapfile> <extract_file>
    EOF
  EOF
end

if extract_file
  # 查找文件对应的 invokeID
  invokeids = `tshark -r '#{pcap_file}' -Y 'mms.FileName_item == "#{extract_file}"' -Tfields -e mms.invokeID`.split.join(' ')
  # 对应 invokeID 的 frsmID
  frsmids = `tshark -r '#{pcap_file}' -Y 'mms.invokeID in {#{invokeids}} && mms.confirmedServiceResponse && mms.frsmID' -Tfields -e mms.frsmID`.split.join(' ')
  # 通过 frsmID 查找到对应内容请求包
  invokeids = `tshark -r '#{pcap_file}' -Y 'mms.fileRead in {#{frsmids}} && mms.confirmedServiceRequest' -Tfields -e mms.invokeID`.split

  invokeids.each do |invokeid|
    hex_data = `tshark -r '#{pcap_file}' -Y 'mms.invokeID == #{invokeid} && mms.confirmedServiceResponse' -Tfields -e mms.fileData`.chomp.delete(':')

    if hex_data.empty?
      frame_number = `tshark -r '#{pcap_file}' -Y 'mms.invokeID == #{invokeid} && mms.confirmedServiceRequest' -Tfields -e frame.number`.to_i
      puts "Not Find Response PDU"
      puts "Request PDU Frame: #{frame_number}"
    else
      puts [hex_data].pack('H*')
    end
  end
else
  file_directory_json = `tshark -r #{pcap_file} -Y 'mms.confirmedServiceResponse == 77' -Tjson -e mms.FileName_item -e mms.sizeOfFile -e mms.lastModified`
  file_directory = Oj.load(file_directory_json).map{|data| a, *b = data["_source"]["layers"].values; a.zip(*b) }.flatten(1).uniq

  mms_fileopen_request =
    `tshark -r #{pcap_file} -Y 'mms.confirmedServiceRequest == 72' -Tfields -e mms.invokeID -e mms.FileName_item`.
    each_line(chomp: true).
    map(&:split)

  mms_fileopen_response =
    `tshark -r #{pcap_file} -Y 'mms.confirmedServiceResponse == 72' -Tfields -e mms.invokeID -e mms.sizeOfFile -e mms.lastModified`.
    each_line(chomp: true).
    map{|x| id, size, time = x.split("\t", 3); [id, size, time]}

  mms_fileopen = []
  mms_fileopen_request.each do |id, name|
    _, size, time = mms_fileopen_response.find{|x| x.first == id}
    mms_fileopen << [name, size, time] if size && time
  end
  mms_fileopen.uniq!


  read_files = mms_fileopen_request.map(&:last).uniq
  files = (file_directory | mms_fileopen).uniq{|x| x[0..1]}
  puts "%-25s  %11s\t  %-4s   %s" % ['Time', 'Size', 'OP', 'FileName']
  files.each do |name, size, time|
    read = read_files.include?(name) ? 'READ' : '    '
    puts "%-25s  %11s\t  %-4s   %s" % [time, Filesize.from(size).pretty, read, name]
  end
end

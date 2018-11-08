#!/usr/bin/env ruby
#
# Author L
# Get USB Keyboard Input Data to Png
#

require 'tempfile'

if ARGV.delete '-h'
  puts <<~EOF
    Usage:
      ./usbmouse.rb [option] <pcap_file>
      cat usb_capdata.txt | ./usbmouse.rb -o result.png

    Option: 
      -o <file> Set Output File (Default: mouse.png)
      -left     Left Keystroke
      -right    Right Keystroke
      -move     Mouse Move
      -all      Mouse All (Default)
      -f        Force Mode (Ignore Wireshark Error)
      -v        Verbose Mode
      -h        Help Info
  EOF
  exit
end
verbose = ARGV.delete '-v'
force   = ARGV.delete '-f'
left    = ARGV.delete '-left'
right   = ARGV.delete '-right'
move    = ARGV.delete '-move'
all     = ARGV.delete('-all') || [left, right, move].none?
output  = (i = ARGV.index '-o') ? ARGV.slice!(i,2).last : 'mouse.png'

if ARGV[0] 
  cmd = "tshark -r #{ARGV[0]} -T fields -e usb.capdata #{force ? "2>&-" : ""}"
  data = `#{cmd}`
  unless force
    abort "[!] Error `#{cmd}` " unless $?.success? and `file #{ARGV[0]}`.include? 'capture'
  end
else
  data = ARGF
end

tempfile = Tempfile.new('usb_mouse_data')

posx, posy = 0, 0
data.each_line do |line|
  if line =~ /^(00|01|02):(\h{2}):(\h{2}):\h{2}$/
    action, x, y = $1, $2.to_i(16), $3.to_i(16)
    x -= 256 if x > 127
    y -= 256 if y > 127
    posx += x
    posy += y
    recoding = case action
               when '00' then move
               when '01' then left
               when '02' then right
               else
                 puts "[-] Known operate" if verbose
               end
    tempfile.puts "#{posx} #{posy}" if recoding || all
  end
end

tempfile.close
if tempfile.size.zero?
  puts "[!] Mouse input not found"
  exit
end

cmd = "gnuplot -e \"set terminal png; plot '#{tempfile.path}'\""
data = `#{cmd}`
unless $?.success?
  debug_file = 'mouse_coordinate.txt'
  File.write(debug_file, File.read(tempfile.path)) # copy
  puts "[*] Debug Output: #{debug_file}"
  abort "[!] Error `#{cmd}` "
end

File.binwrite(output, data)
puts "[+] Output: #{output}"
tempfile.unlink

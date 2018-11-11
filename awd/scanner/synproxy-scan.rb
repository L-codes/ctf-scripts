#!/usr/bin/env ruby
#
# Use Bridged for virtual machine
# Dependency nmap tshark
#
__author__ = 'L'

require 'tempfile'
require 'childprocess'
require 'shellwords'
require 'socket'
require 'optparse'

banner = %q[
 ______   ___   _   ____                        ____
/ ___\ \ / / \ | | |  _ \ _ __ _____  ___   _  / ___|  ___ __ _ _ __
\___ \\\ V /|  \| | | |_) | '__/ _ \ \/ / | | | \___ \ / __/ _` | '_ \
 ___) || | | |\  | |  __/| | | (_) >  <| |_| |  ___) | (_| (_| | | | |
|____/ |_| |_| \_| |_|   |_|  \___/_/\_\\\__, | |____/ \___\__,_|_| |_|
      author: L  version: 2.0.0         |___/


]

def create_tshark_cmd(args)
  interface = args[:interface] ? "-i #{args[:interface]}" : ''
  ifaces = Socket.ip_address_list.select(&:ipv4?).map(&:ip_address)
  src_hosts = ifaces.map{|ip| " dst host #{ip} "}.join '||'
  bpf = 'tcp'
  bpf += " && (#{src_hosts})" if src_hosts
  cmd = "tshark #{interface} -f \"#{bpf}\" " +
        "-Y \"tcp.flags.ack==1 && tcp.window_size_value!=0 \" " +
        #"-Y \"tcp.flags.ack==1 && tcp.window_size_value!=0 && tcp.seq==1\" " +
        "-T fields -e ip.src_host -e tcp.srcport"
  puts "[Debug] Exec CMD: #{cmd}" if args[:debug]
  cmd.shellsplit
end

def create_nmap_cmd(args)
  ports = args[:ports] ? "-p #{args[:ports]}" : ''
  cmd = "nmap -T5 -sT -Pn -n #{ports}".shellsplit + ARGV
  puts "[Debug] Exec CMD: #{cmd.shelljoin}" if args[:debug]
  cmd
end

def get_result(io)
  io.rewind
  result = Hash.new {|hash,key| hash[key] = []}
  data = io.read
  ips = `nmap -Pn -sn -n -sL #{ARGV.shelljoin}`.b
  data.scan(/([.\d]+)\t(\d+)/) do |ip, port|
    result[ip] << port
  end
  result.select{|ip| ips.match? /\b#{Regexp.quote(ip)}\b/ }
end

def print_result(io)
  get_result(io).each do |ip, ports|
    puts "Scan report for #{ip}"
    puts "PORT   STATE   SERVICE"
    ports.map(&:to_i).sort.uniq.each do |port|
      server = Socket.getservbyport(port) rescue 'unkown'
      puts "%-6s open    %s" % [port, server]
    end
    puts
  end
end

def start(args)
  tshark_cmd = create_tshark_cmd(args)
  nmap_cmd = create_nmap_cmd(args)

  tshark = ChildProcess.build(*tshark_cmd)
  tshark_io = Tempfile.new
  tshark.io.stdout = tshark_io
  tshark.start
  sleep 1

  nmap = ChildProcess.build(*nmap_cmd)
  if args[:nmap]
    nmap.io.inherit!
  else
    nmap_io = Tempfile.new
    nmap.io.stdout = nmap_io
  end
  nmap.start
  nmap.wait
  if args[:nmap]
    sep = '-'*25
    puts "\n\n#{sep + " SYN Proxy Scan Result " + sep}\n\n\n"
  else
    nmap_io.seek(-100, IO::SEEK_CUR)
    last = nmap_io.read[/^.*?\Z/]
  end

  sleep 2
  tshark.stop
  
  print_result(tshark_io)
  puts last.gsub('Nmap', 'SYN Proxy Scan') if last && !args[:nmap]
end


if __FILE__ == $PROGRAM_NAME
  args = {
    interface: nil,
    ports: nil,
    debug: false,
    nmap: false
  }
  optparser = OptionParser.new do |opts|
    opts.banner = banner + "Usage: ./synproxy-scan.rb [options] <target specification>"
    opts.on('-i <iface>', '--interface', String, "Specify sniff network interface(tshark). [default: auto]")
    opts.on('-p <ports>', '--ports', String, "Specify scan ports [default: most common 1,000 ports]")
    opts.on('-n', '--nmap', "Nmap Interaction Mode")
    opts.on('-d', '--debug', "Debug Mode")
    opts.separator "\nExamples:"
    opts.separator "  ./synproxy-scan.rb 192.168.1.1"
    opts.separator "  ./synproxy-scan.rb -p 1-100 192.168.1.1"
    opts.separator "  ./synproxy-scan.rb -i eth0 -p 1-20,30-100,3389 192.168.1.1/24 github.com"
  end
  optparser.parse! into: args
  puts "[Debug] Args: #{args}" if args[:debug]

  if ARGV.empty? 
    puts "[!] Please specify target"
    puts optparser.help
  else
    puts banner
    start(args)
  end
end

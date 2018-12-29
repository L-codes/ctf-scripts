#!/usr/bin/env ruby
#
# Use Bridged for virtual machine
# Dependency nmap tshark
#
__author__ = 'L'

require 'l-tools'
require 'socket'
require 'optparse'

banner = %q[
 ______   ___   _   ____                        ____
/ ___\ \ / / \ | | |  _ \ _ __ _____  ___   _  / ___|  ___ __ _ _ __
\___ \\\ V /|  \| | | |_) | '__/ _ \ \/ / | | | \___ \ / __/ _` | '_ \
 ___) || | | |\  | |  __/| | | (_) >  <| |_| |  ___) | (_| (_| | | | |
|____/ |_| |_| \_| |_|   |_|  \___/_/\_\\\__, | |____/ \___\__,_|_| |_|
      author: L  version: 2.1.0         |___/


]

def create_tshark(args)
  ifaces = Socket.ip_address_list.select(&:ipv4?).map(&:ip_address)
  src_hosts = ifaces.map{|ip| " dst host #{ip} "}.join '||'
  bpf = src_hosts ? "tcp && (#{src_hosts})" : "tcp"
  LTools::Tshark.capture(
    interface: args[:interface],
    bpf: bpf,
    filter: 'tcp.flags.ack==1 && tcp.window_size_value!=0',
    fields: 'ip.src_host tcp.srcport'
  )
end

def print_result(records)
  ip_port_map = records.group_by(&:first).transform_values{|x| x.map(&:last) }
  ips = `nmap -Pn -sn -n -sL #{ARGV.shelljoin}`.b
  ip_port_map.each do |ip, ports|
    next unless ips.match? /\b#{Regexp.quote(ip)}\b/
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
  tshark = create_tshark(args)
  tshark.start
  sleep 1

  nmap = LTools::Nmap.portscan(
    ARGV,
    ports: args[:ports],
    mode: 'T'
  )
  nmap.io_inherit! if args[:nmap]
  nmap.start
  nmap.wait

  if args[:nmap]
    sep = '-'*25
    puts "\n\n#{sep + " SYN Proxy Scan Result " + sep}\n\n\n"
  else
    last = nmap.stdout.read[/^.*?\Z/]
  end

  sleep 2
  tshark.stop
  
  print_result(tshark.records)
  puts last.gsub('Nmap', 'SYN Proxy Scan') if last
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
  if args[:debug]
    puts "[Debug] Args: #{args}"
    LTools.verbose = true
  end

  if ARGV.empty? 
    puts "[!] Please specify target"
    puts optparser.help
  else
    puts banner
    start(args)
  end
end

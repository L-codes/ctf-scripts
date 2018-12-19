#!/usr/bin/env ruby
#
# base92 encode/decode
#

class Base92

  def self.decode(str)
    return '' if str == '~'

    bitstr = ''
    str.chars.each_slice(2) do |x,y|
      if y
        n = base92_ord(x)*91 + base92_ord(y)
        bitstr += '%013b' % n
      else
        n = base92_ord(x)
        bitstr += '%06b' % n
      end
    end

    bitstr.scan(/[01]{8}/).map{|n| n.to_i(2)}.pack('C*')
  end

  def self.encode(str)
    return '~' if str == ''
    
    bitstr = str.bytes.map{|x| '%08b' % x}.join
    bitstr.chars.each_slice(13).map{|bs|
      bs = bs.join
      case bs.size
      when 13
        x, y = bs.to_i(2).divmod(91)
        base92_chr(x) + base92_chr(y)
      when 0..6
        base92_chr((bs+'0'*(6-bs.size)).to_i(2))
      else
        x, y = (bs+'0'*(13-bs.size)).to_i(2).divmod(91)
        base92_chr(x) + base92_chr(y)
      end
    }.join
  end

  private

  def self.base92_chr(val)
    raise 'val must be in (0..91)' unless (1..91).include? val
    return '!' if val == 0
    val <= 61 ? ('#'.ord + val - 1).chr : ('a'.ord + val - 62).chr
  end

  def self.base92_ord(val)
    case val
    when '!'
      0
    when '#'..'_'
      val.ord - '#'.ord + 1
    when 'a'..'}'
      val.ord - 'a'.ord + 62
    else
      raise 'val is not a base92 character'
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.size == 2
    abort "No such option '#{ARGV[0]}'" unless 'ed'.index ARGV[0]
    abort "No such file '#{ARGV[1]}'"   unless File.exist? ARGV[1]

    data = File.binread(ARGV[1]).strip
    if ARGV[0] == 'e'
			puts Base92.encode data
    else
			puts Base92.decode data
    end
  else
    puts <<~EOF
    usage:
      base92.rb <option> <file>
    option:
      e - encode
      d - decode
    EOF
  end
end


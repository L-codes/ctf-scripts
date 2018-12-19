#!/usr/bin/env ruby
#
# Author L
# zwsp-steg
# Reference: https://github.com/offdev/zwsp-steg-js
#

class ZWSP

  MODE_ZWSP = 0
  MODE_FULL = 1

  ZERO_WIDTH_SPACE = "\u200b"
  ZERO_WIDTH_NON_JOINER = "\u200c"
  ZERO_WIDTH_JOINER = "\u200d"
  LEFT_TO_RIGHT_MARK = "\u200e"
  RIGHT_TO_LEFT_MARK = "\u200f"

  ArrayZWSP = [
    ZERO_WIDTH_SPACE,
    ZERO_WIDTH_NON_JOINER,
    ZERO_WIDTH_JOINER,
  ]

  ArrayFULL = [
    ZERO_WIDTH_SPACE,
    ZERO_WIDTH_NON_JOINER,
    ZERO_WIDTH_JOINER,
    LEFT_TO_RIGHT_MARK,
    RIGHT_TO_LEFT_MARK,
  ]


  def self.get_padding_length(mode)
    mode == MODE_ZWSP ? 11 : 7
  end 


  def self.encode(message, mode: MODE_FULL)
    return '' if message.empty?

    alphabet = mode == MODE_ZWSP ? ArrayZWSP : ArrayFULL
    padding = get_padding_length(mode)
    encoded = ''
    message.each_char do |char|
      code = '0' * padding + char.ord.to_s(alphabet.size).to_i.to_s
      code = code[(code.size-padding)..-1]
      code.each_char do |c|
        encoded += alphabet[c.to_i]
      end
    end
    encoded
  end


  def self.decode(message, mode: MODE_FULL)
    alphabet = mode == MODE_ZWSP ? ArrayZWSP : ArrayFULL
    padding = get_padding_length(mode)

    encoded = ''
    #message.chars.map{|c| alphabet.index(c)}.join
    message.each_char do |char|
      index = alphabet.index(char)
      encoded << index.to_s if index
    end

    raise 'Unknown encoding detected!' if encoded.size % padding != 0

    decoded = ''
    cur_char = ''
    encoded.chars.each_with_index do |char, index|
      cur_char += char
      if index > 0 and (index + 1) % padding == 0
        decoded += cur_char.to_i(alphabet.size).chr
        cur_char = ''
      end
    end
    decoded
  end
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.size == 2
    abort "No such option '#{ARGV[0]}'" unless 'ed'.index ARGV[0]
    abort "No such file '#{ARGV[1]}'"   unless File.exist? ARGV[1]

    data = File.read(ARGV[1])
    if ARGV[0] == 'e'
			puts ZWSP.encode data
    else
			puts ZWSP.decode data
    end
  else
    puts <<~EOF
    usage:
      zwsp-steg.rb <option> <file>
    option:
      e - encode
      d - decode
    EOF
  end
end

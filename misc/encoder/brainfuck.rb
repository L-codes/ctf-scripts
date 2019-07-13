#!/usr/bin/env ruby
#
# Author L
# brainfuck && ook text encode/decode
#

module Brainfuck
  module_function

  def decode code
    le = code.length
    cp = -1 # code pointer
    p = 0   # cell pointer
    c = [0] # cells
    bm = {} # bracket map, jump directly to matching brackets! :)
    bc = 0  # bracket counter
    s = []  # bracket stack
    ccp = 0 # code pointer for cleaned code

    commands = [">", "<", "+", "-", ".", "[", "]", ","]
    cleaned  = []

    until (cp+=1) == le
      case code[cp]
        when ?[ then s.push(ccp) && bc += 1
        when ?] then (bm[s.pop] = ccp) && bc -= 1
      end
      bc < 0 && raise("Ending Brainfuck without opening, mismatch at #{cp}") && exit
      commands.include? code[cp] && (cleaned.push code[cp]) && ccp += 1
    end

    !s.empty? && raise("Opening Brainfuck without closing, mismatch at #{s.pop}") && exit

    cp = -1

    output = ''
    until (cp+=1) == le
      case cleaned[cp]
        when ?> then (p += 1) && c[p].nil? && c[p] = 0
        when ?< then p <= 1 ? p = 0 : p -= 1
        when ?+ then c[p] <= 254 ? c[p] += 1 : c[p] = 0
        when ?- then c[p] >= 1 ? c[p] -= 1 : c[p] = 255
        when ?[ then c[p] == 0 && cp = bm[cp]
        when ?] then c[p] != 0 && cp = bm.key(cp)
        when ?. then output << c[p]
        when ?, then c[p] = get_character.to_i
      end
    end
    output
  end

  def encode msg
    result = ''
    value = 0
    msg.each_byte do |c|
      diff = c - value
      value = c

      if diff.zero?
        result += '>.<'
        next
      end

      op = ( diff > 0 ? '+' : '-' )
      if diff.abs < 10
        result += ('>' + op * diff.abs)
      else
        _loop = Math.sqrt(diff.abs).to_i
        result += '+' * _loop
        result += "[->#{op * _loop}<]>#{op * (diff.abs - _loop ** 2)}"
      end

      result += '.<'
    end

    result.gsub('<>', '')
  end

  def ook_encode msg
    char_map = {
      '>' => 'Ook. Ook? ',
      '<' => 'Ook? Ook. ',
      '+' => 'Ook. Ook. ',
      '-' => 'Ook! Ook! ',
      '.' => 'Ook! Ook. ',
      ',' => 'Ook. Ook! ',
      '[' => 'Ook! Ook? ',
      ']' => 'Ook? Ook! ',
    }
    encode(msg).each_char.map(&char_map).join.strip
  end

  def short_ook_encode msg
    ook_encode(msg).gsub(/[^.?!]/, '')
  end

  def ook_decode code
		char_map = {
			'.?' => '>',
			'?.' => '<',
			'..' => '+',
			'!!' => '-',
			'!.' => '.',
			'.!' => ',',
			'!?' => '[',
			'?!' => ']',
    }
    code = code.gsub(/[^.?!]/, '').each_char.each_slice(2).map(&:join).map(&char_map)
    decode(code)
  end
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.size == 2
    op, file = ARGV
    data = File.read(file)
    output =
      case op.to_i
      when 0
        Brainfuck.decode(data)
      when 1
        Brainfuck.ook_decode(data)
      when 2
        Brainfuck.encode(data)
      when 3
        Brainfuck.ook_encode(data)
      when 4
        Brainfuck.short_ook_encode(data)
      end
    puts output
  else
    puts <<~EOF
    usage:
      brainfuck.rb <option> <file>
    option:
      0 - Brainfuck to Text
      1 - Ook to Text
      2 - Text to Brainfuck
      3 - Text to Ook
      4 - Text to Short Ook
    EOF
  end
end

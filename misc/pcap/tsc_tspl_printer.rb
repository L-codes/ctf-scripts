#!/usr/bin/env ruby
#
# Author L
# TSC TSPL Printer to Image
#

require 'pycall/import'
include PyCall::Import
pyfrom :PIL, import: :Image
ENV['PYTHON'] = 'python3'

require 'slop'

begin
  opts = Slop.parse do |o|
    o.banner = 'Usage: ./tsc_tspl_printer.rb [options] <.pcap|.tspl>+'
    o.separator ""
    o.separator "Options:"
    o.string '-s', '--save',    'Save image to directory' do |s|
      Dir.mkdir(s) unless File.directory? s
    end
    o.bool   '-n', '--no-show', 'Do not display images directly'
    o.bool   '-a', '--all',     'all content'
    o.on     '-h', '--help' do
      puts o
      exit
    end
  end
rescue Slop::UnknownOption, Slop::MissingArgument => e
  abort e.to_s
end

ARGV.replace opts.arguments

imgfile_index = 1
bar_points = []
paste_imgs = []
bar_width = bar_height = 0

$<.each_line do |line|
  if line.delete_prefix! 'BAR'
    # BAR x, y, width, height
    sx, sy, width, height = line.split(?,).map(&:to_i)
    (sx..(sx+width)).each do |x|
      (sy..(sy+height)).each do |y|
        bar_width = [x, bar_width].max
        bar_height = [y, bar_height].max
        bar_points << [x,y]
      end
    end
  elsif line.delete_prefix! 'BITMAP'
    # BITMAP x,y,width,height,data
    # data: data.bits to width*8 x height
    x, y, width, height, _, data = line.b.split(?,, 6)
    x, y, width, height = [x, y, width, height].map(&:to_i)
    im = Image.new('L', [width * 8, height])
    im.putdata(data.strip.unpack1('B*').chars.map{|c| (c.to_i^1)*255})
    bar_width = [x + width, bar_width].max
    bar_height = [y + height, bar_height].max
    paste_imgs << [[x,y], im]
    if opts.all?
      im = im.rotate(180)
      if opts.save?
        im.save("#{opts[:save]}/#{imgfile_index}.png")
        imgfile_index += 1
      end
      im.show() unless opts.no_show?
    end
  end
end

im = Image.new('L', [bar_width + 20, bar_height + 20])
bar_points.each{|point| im.putpixel(point, 255) }
paste_imgs.each{|point, img| im.paste(img, point) }
im = im.rotate(180)
im.save("#{opts[:save]}/printer.png") if opts.save?
im.show() unless opts.no_show?

#!/usr/bin/env ruby --yjit
require 'fileutils'
require 'optimist'
require_relative 'lib/monkey_patch.rb'
require_relative 'lib/color.rb'
require_relative 'lib/image.rb'

PRNG = Random.new 1337

#NUM_COLORS = 32 # 64 # 32
#WIDTH = 256 # 512 # 256
#HEIGHT = 128 # 512 # 128
#START = [WIDTH / 6, HEIGHT / 2]

opts = Optimist::options do
  banner <<-EOS
Use every color in the hex mapping exactly once.

Usage:
  gen.rb [options]
where [options] are:

EOS

  opt :colors, "Number of colors", :type => :integer, :default => 32
  opt :size, "Size ('WIDTHxHEIGHT') of output", :type => :string, :default => "256x128"
  opt :start, "Starting pixel ('x,y')", :type => :string, :default => "128,64"
  opt :checkpoints, "Number of checkpoint images to make", :type => :integer, :default => 10
  opt :output, "Where to write the checkpoint images", :type => :string, :default => "output"
  opt :debug, "Print the debug statements", :type => :boolean
  opt :parallel, "How many cores to use", :type => :integer, :default => 4
end

$debug = opts[:debug]
opts[:size]  = opts[:size].split("x").map(&:to_i)
opts[:start] = opts[:start].split(",").map(&:to_i)

WIDTH, HEIGHT = *opts[:size]

def debug(*args)
  puts(*args) if $debug
end

def d(*args)
  p(*args) if $debug
end

# When placing a color, place it in the location where the average color
# differential from its neighbors is the minimum
#
# I'm not able to get much more than 60% CPU out of this. I should investigate
# vectorizing this somehow (not sure how)
def calc_diff(pixels, coord, c)
  diffs = []
  neighbors(coord).each do |n|
    nc = pixels[*n]
    if nc
      diffs << (nc - c).mag_2 if nc
    end
  end

  #diffs.avg * (9 - diffs.size) ** 2
  diffs.min
end

# Create every color once and randomize the order
# Need to be converted to RGB or something later on
colors = []

# RGB
opts[:colors].times do |r|
  r = (255 * (r / opts[:colors].to_f)).to_i
  opts[:colors].times do |g|
    g = (255 * (g / opts[:colors].to_f)).to_i
    opts[:colors].times do |b|
      b = (255 * (b / opts[:colors].to_f)).to_i
      colors << RGB.new(r, g, b)
    end
  end
end

raise "`colors.size` (#{colors.size}) must equal WIDTH * HEIGHT (#{WIDTH * HEIGHT})" unless colors.size == WIDTH * HEIGHT

#colors = colors.shuffle :random => PRNG
colors = colors.sort_by {|rgb| rgb.hue }.reverse

# Temporary place to do work instead of writing to bitmap
pixels = Matrix.build(WIDTH, HEIGHT) {}

available = Set.new

# calculate checkpoints in advance
num_checks  = opts[:checkpoints].to_i
checkpoints = (1..num_checks).map {|i| [i * colors.size / num_checks - 1, i - 1] }.to_h

# loop through all colors that we want to place
colors.size.times do |i|
#5.times do |i|

  # Debug
  if i % 256 == 0
    debug "#{"%0.4f" % (100.0 * i / (WIDTH * HEIGHT))}%, queue #{available.size}"
  end

  if available.size == 0
    best = opts[:start]
  else
    # Find the best place from the list of available coordinates
    # uses parallel processing, most expensive step
    if available.size > 2000
      sorted = available.parallel_sort_by(:cores => opts[:parallel]) {|c| calc_diff(pixels, c, colors[i]) }
    else
      # too small, don't parallelize it
      sorted = available.sort_by {|c| calc_diff(pixels, c, colors[i]) }
    end

    best = sorted[0]
  end

  # Put pixel where it belongs
  pixels[*best]   = colors[i]

  available.delete best

  # adjust available list
  neighbors(best).each do |neighbor|
    # don't overwrite pixels
    available << neighbor unless pixels[*neighbor]
    #if pixels[*neighbor]
    #  puts "uhoh #{neighbor.inspect}"
    #end
  end

  if checkpoints[i]
    FileUtils.mkdir_p opts[:output]
    #cleaned = remove_coral pixels

    debug "Checkpoint #{checkpoints[i]}"
    img = ChunkyPNG::Image.new WIDTH, HEIGHT, ChunkyPNG::Color::TRANSPARENT

    HEIGHT.times do |y|
      WIDTH.times do |x|
        rgb = pixels[x, y]
        if rgb
          img[x, y] = ChunkyPNG::Color.rgba rgb.R, rgb.G, rgb.B, 255
        end
      end
    end

    fname = "#{opts[:output]}/checkpoint_#{"%02d" % checkpoints[i]}.png"
    img.save fname, :interlace => true
    debug "Wrote #{fname}"
  end

end


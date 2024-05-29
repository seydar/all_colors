require 'chunky_png'
require 'matrix'
require_relative 'monkey_patch.rb'

class Array
  def avg
    sum.to_f / size
  end
end

PRNG = Random.new 1337

NUM_COLORS = 32 # bits
WIDTH = 256
HEIGHT = 128
START = [128, 64]

RGB = Struct.new :R, :G, :B

def neighbors(coord)
  x, y   = *coord
  neighs = [x - 1, x, x + 1].product([y - 1, y, y + 1]) - [x, y]
  neighs.filter {|x, y| x < WIDTH && x >= 0 && y < HEIGHT && y >= 0 }
end

def color_diff(c1, c2)
  r = c1.R - c2.R
  g = c1.G - c2.G
  b = c1.B - c2.B

  r * r + g * g + b * b
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
    diffs << color_diff(nc, c) if nc
  end

  diffs.avg
  #diffs.min
end

# Create every color once and randomize the order
# Need to be converted to RGB or something later on
colors = []

# RGB
NUM_COLORS.times do |r|
  r = (255 * (r / NUM_COLORS.to_f)).to_i
  NUM_COLORS.times do |g|
    g = (255 * (g / NUM_COLORS.to_f)).to_i
    NUM_COLORS.times do |b|
      b = (255 * (b / NUM_COLORS.to_f)).to_i
      colors << RGB.new(r, g, b)
    end
  end
end

raise "`colors.size` must equal WIDTH * HEIGHT" unless colors.size == WIDTH * HEIGHT

colors = colors.shuffle :random => PRNG
colors = colors.sort_by {|c| c.R }

# Temporary place to do work instead of writing to bitmap
#pixels = Array.new(WIDTH) { Array.new(HEIGHT) }
pixels = Matrix.build(WIDTH, HEIGHT) {}

available = Set.new

# calculate checkpoints in advance
checkpoints = (1..10).map {|i| [i * colors.size / 10 - 1, i - 1] }.to_h

# loop through all colors that we want to place
colors.size.times do |i|
#3.times do |i|

  # Debug
  if i % 256 == 0
    puts "#{"%0.4f" % (100.0 * i / (WIDTH * HEIGHT))}%, queue #{available.size}"
  end

  if available.size == 0
    best = START
  else
    # Find the best place from the list of available coordinates
    # uses parallel processing, most expensive step
    if available.size > 2000
      best = available.parallel_sort_by {|c| calc_diff(pixels, c, colors[i]) }[0]
    else
      # too small, don't parallelize it
      best = available.sort_by {|c| calc_diff(pixels, c, colors[i]) }[0]
    end
  end
  #p best

  # Put pixel where it belongs
  pixels[*best] = colors[i]
  available.delete best

  # adjust available list
  neighbors(best).each do |neighbor|
    # don't overwrite pixels
    available << neighbor unless pixels[*neighbor]
  end

  if checkpoints[i]
    puts "Checkpoint #{i}"
    img = ChunkyPNG::Image.new WIDTH, HEIGHT, ChunkyPNG::Color::TRANSPARENT

    HEIGHT.times do |y|
      WIDTH.times do |x|
        rgb       = pixels[x, y]
        if rgb
          img[x, y] = ChunkyPNG::Color.rgba rgb.R, rgb.G, rgb.B, 255
        end
      end
    end

    check = ARGV[0] || "result"
    img.save "#{check}_#{checkpoints[i]}.png", :interlace => true
  end

end


require 'chunky_png'
require 'matrix'
require 'fileutils'
require_relative 'monkey_patch.rb'

class Array
  def avg
    sum.to_f / size
  end
end

PRNG = Random.new 1337

NUM_COLORS = 64 # 32
WIDTH = 512 # 256
HEIGHT = 512 # 128
START = [WIDTH / 6, HEIGHT / 2]

RGB = Struct.new :R, :G, :B

def neighbors(coord)
  x, y   = *coord
  neighs = [x - 1, x, x + 1].product([y - 1, y, y + 1]) - [x, y]
  neighs.filter {|x, y| x < WIDTH && x >= 0 && y < HEIGHT && y >= 0 }
end

# This is the square of the euclidean distance.
# Since we're comparing everything, we don't need to compute the sqrt,
# since the order wouldn't change
def euclidean(c1, c2)
  r = c1.R - c2.R
  g = c1.G - c2.G
  b = c1.B - c2.B

  r * r + g * g + b * b
end

def manhattan(c1, c2)
  r = c1.R - c2.R
  g = c1.G - c2.G
  b = c1.B - c2.B

  r + g + b 
end

def hue(rgb)
  max = [rgb.R, rgb.G, rgb.B].max.to_f
  min = [rgb.R, rgb.G, rgb.B].min.to_f

  return 0.0 if max == min

  hue = case max
        when rgb.R
          (rgb.G - rgb.B) / (max - min)
        when rgb.G
          2.0 + (rgb.B - rgb.R) / (max - min)
        when rgb.B
          4.0 + (rgb.R - rgb.G) / (max - min)
        end

  # commented out because this is only used for ordering, so we don't need these
  # affine transformations

  #if hue * 60 < 0
  #  hue * 60 + 360
  #else
  #  hue * 60
  #end
end

def remove_coral(pixels)
  pxls = pixels.clone

  WIDTH.times do |x|
    next if x == 0 or x == WIDTH

    HEIGHT.times do |y|
      next if y == 0 or y == HEIGHT

      if pixels[x - 1, y] == nil && pixels[x + 1, y] == nil
        pxls[x, y] = nil
      end

      if pixels[x, y - 1] == nil && pixels[x, y + 1] == nil
        pxls[x, y] = nil
      end
    end
  end

  pxls
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
      diffs << euclidean(nc, c) if nc
    end
  end

  diffs.avg * (9 - diffs.size) ** 2
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

raise "`colors.size` (#{colors.size}) must equal WIDTH * HEIGHT (#{WIDTH * HEIGHT})" unless colors.size == WIDTH * HEIGHT

colors = colors.shuffle :random => PRNG
colors = colors.sort_by {|rgb| hue rgb }.reverse

# Temporary place to do work instead of writing to bitmap
#pixels = Array.new(WIDTH) { Array.new(HEIGHT) }
pixels = Matrix.build(WIDTH, HEIGHT) {}

available = Set.new

# calculate checkpoints in advance
num_checks  = (ARGV[1] || 10).to_i
checkpoints = (1..num_checks).map {|i| [i * colors.size / num_checks - 1, i - 1] }.to_h

# loop through all colors that we want to place
colors.size.times do |i|

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
      sorted = available.parallel_sort_by {|c| calc_diff(pixels, c, colors[i]) }
    else
      # too small, don't parallelize it
      sorted = available.sort_by {|c| calc_diff(pixels, c, colors[i]) }
    end

    best = sorted[0]
  end

  # Put pixel where it belongs
  pixels[*best] = colors[i]
  available.delete best

  # adjust available list
  neighbors(best).each do |neighbor|
    # don't overwrite pixels
    available << neighbor unless pixels[*neighbor]
  end

  if checkpoints[i]
    check = ARGV[0] || "result"
    FileUtils.mkdir_p check
    #cleaned = remove_coral pixels

    puts "Checkpoint #{checkpoints[i]}"
    img = ChunkyPNG::Image.new WIDTH, HEIGHT, ChunkyPNG::Color::TRANSPARENT

    HEIGHT.times do |y|
      WIDTH.times do |x|
        rgb = pixels[x, y]
        if rgb
          img[x, y] = ChunkyPNG::Color.rgba rgb.R, rgb.G, rgb.B, 255
        end
      end
    end

    img.save "#{check}/#{check}_#{"%02d" % checkpoints[i]}.png", :interlace => true
  end

end


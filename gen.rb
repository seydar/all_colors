require 'fileutils'
require_relative 'lib/monkey_patch.rb'
require_relative 'lib/color.rb'
require_relative 'lib/image.rb'

PRNG = Random.new 1337

NUM_COLORS = 32 # 64 # 32
WIDTH = 256 # 512 # 256
HEIGHT = 128 # 512 # 128
START = [WIDTH / 6, HEIGHT / 2]


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

#colors = colors.shuffle :random => PRNG
colors = colors.sort_by {|rgb| rgb.hue }.reverse

# Temporary place to do work instead of writing to bitmap
#pixels = Array.new(WIDTH) { Array.new(HEIGHT) }
pixels = Matrix.build(WIDTH, HEIGHT) {}
avgs = Matrix.build(WIDTH, HEIGHT) { [RGB.new(0, 0, 0), 0] }

available = Set.new

# calculate checkpoints in advance
num_checks  = (ARGV[1] || 10).to_i
checkpoints = (1..num_checks).map {|i| [i * colors.size / num_checks - 1, i - 1] }.to_h

# loop through all colors that we want to place
#colors.size.times do |i|
5.times do |i|

  # Debug
  #if i % 256 == 0
    puts "#{"%0.4f" % (100.0 * i / (WIDTH * HEIGHT))}%, queue #{available.size}"
  #end

  if available.size == 0
    best = START
  else
    # Find the best place from the list of available coordinates
    # uses parallel processing, most expensive step
    #if available.size > 2000
    #  sorted = available.parallel_sort_by {|c| calc_diff(pixels, c, colors[i]) }
    #else
    #  # too small, don't parallelize it
    #  sorted = available.sort_by {|c| calc_diff(pixels, c, colors[i]) }
    #end

    sorted = available.sort_by do |coord|
      avg, num = *avgs[*coord]
      num      = [1, num].max
      (colors[i] - avg / num.to_f).mag_2
    end

    best = sorted[0]
  end
  p(available.map do |coord|
      avg, num = *avgs[*coord]
      num      = [1, num].max
      [coord, (colors[i] - avg / num.to_f).mag_2]
  end.sort_by {|a, b| b })
  p best

  # Put pixel where it belongs
  pixels[*best]   = colors[i]

  # Adjust the average for that area
  avg, num = *avgs[*best]
  avgs[*best][0]  = (avg * num / (num + 1.0)) + colors[i].sq / (num + 1.0)
  avgs[*best][1] += 1
  available.delete best

  require 'pry'
  binding.pry

  # adjust available list
  neighbors(best).each do |neighbor|
    # don't overwrite pixels
    available << neighbor unless pixels[*neighbor]
    if pixels[*neighbor]
      puts "uhoh #{neighbor.inspect}"
    end
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


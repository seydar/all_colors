#!/usr/bin/env -S ruby --disable-yjit
require 'fileutils'
require 'optimist'
require 'hsluv'
require_relative 'lib/monkey_patch.rb'
require_relative 'lib/color.rb'
require_relative 'lib/image.rb'
require_relative 'lib/neighbors.rb'
require_relative 'lib/sorting.rb'

require 'numo/narray'
require 'pry'

PRNG = Random.new 1138

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

  opt :input, "Input file with extra definitions", :type => :string
  opt :colors, "Number of colors", :type => :integer, :default => 32
  opt :size, "Size ('WIDTHxHEIGHT') of output", :type => :string, :default => "256x128"
  opt :start, "Starting pixel ('x,y')", :type => :string, :default => "128,64"
  opt :checkpoints, "Number of checkpoint images to make", :type => :integer, :default => 10
  opt :directory, "Where to write the checkpoint images", :type => :string, :default => "output"
  opt :debug, "Print the debug statements", :type => :boolean
  opt :parallel, "How many cores to use", :type => :integer, :default => 0
  opt :hsluv, "Sort by HSLUV", :type => :boolean, :default => false
  opt :profiling, "Profile the code", :type => :boolean, :default => false
  opt :output, "File to save the final version as", :type => :string, :default => ""
end

$debug = opts[:debug]
opts[:size]  = opts[:size].split("x").map(&:to_i)
opts[:start] = opts[:start].split(",").map(&:to_i)

# don't use constants because we'll get yelled at for reassigning to them
if opts[:input]
  load opts[:input]
  opts[:size]      = Specific::SIZE
  opts[:start]     = Specific::START
  opts[:directory] = Specific::DIRECTORY
  opts[:colors]    = Specific::COLORS
  opts[:profiling] ||= Specific::PROFILING
else
  require_relative "lib/specific.rb"
end

WIDTH, HEIGHT = *opts[:size]

debug "Creating an image of #{opts[:size].inspect} in #{opts[:directory]}"

FileUtils.mkdir_p opts[:directory]

run_id = (rand * 100_000).to_i
opts[:output] = "#{run_id}.png"

if opts[:input]
  FileUtils.cp opts[:input], File.join(opts[:directory], "#{run_id}.rb")
else
  open(File.join(opts[:directory], "#{run_id}.yaml")) do |f|
    f.write YAML.dump(opts)
  end
end

def scope
  yield
end


# Create a new scope for the colors variable so that it can be GCed
scope do
  
  # Create every color once and randomize the order
  # Need to be converted to RGB or something later on
  colors = []
  
  # RGB
  opts[:colors].times do |r|
    r = ((r / opts[:colors].to_f))
    opts[:colors].times do |g|
      g = ((g / opts[:colors].to_f))
      opts[:colors].times do |b|
        b = ((b / opts[:colors].to_f))
        colors << RGB.new(r, g, b)
      end
    end
  end
  
  raise "`colors.size` (#{colors.size}) must <= WIDTH * HEIGHT (#{WIDTH * HEIGHT})" unless colors.size <= WIDTH * HEIGHT
  
  HSLUV = opts[:hsluv] || Specific::HSLUV
  
  
  if HSLUV
    colors = transform(colors, :to => :hsluv).sort_by {|c| c.vector.to_a }
  else
    colors = colors.map do |c|
      RGB.new(*(c * 255).vector.map {|f| f.round.to_i })
    end
    colors = colors.sort_by {|rgb| rgb.hue }
  end
  
  
  colors = Specific::order colors

  open "/tmp/colors.txt", "w" do |f|
    colors.each do |c|
      f.puts Marshal.dump(c.vector)
    end
  end
end

GC.start

class Cache
  def initialize(&blk)
    @cache = Hash.new do |h, k|
      h[k] = Hash.new do |h_, k_|
        h_[k_] = blk.call
      end
    end
  end

  def [](i, j)
    @cache[i][j]
  end

  def []=(i, j, value)
    @cache[i][j] = value
  end
end


# Temporary place to do work instead of writing to bitmap
#pixels  = Matrix.build(WIDTH, HEIGHT) {}
pixels = Cache.new {}

if HSLUV
  caching = Matrix.build(WIDTH, HEIGHT) { {:squares => 0.0, :sum => 0.0, :size => 0} }
else
  #caching = Matrix.build(WIDTH, HEIGHT) { {:squares => 0.0, :sum => RGB.new(0.0, 0.0, 0.0), :size => 0} }
  caching = Cache.new { {:squares => 0.0, :sum => RGB.new(0.0, 0.0, 0.0), :size => 0} }

  # size, squares, first, middle, r, g, b
  caching2 = Numo::DFloat.zeros(WIDTH * HEIGHT, 10)
end

available = Set.new

# calculate checkpoints in advance
num_checks  = opts[:checkpoints].to_i
checkpoints = (1..num_checks).map {|i| [i * (opts[:colors] ** 3) / num_checks - 1,
                                        i - 1] }.to_h

profile :profile => opts[:profiling] do

  times = []
  cores = nil


  #colors.size.times do |i|
  i = 0
  File.open("/tmp/colors.txt", "r").each_line do |data|
    color = RGB.new(*Marshal.load(data))
  
    # Debug
    if i % 512 == 0
      debug "#{"%0.4f" % (100.0 * i / (WIDTH * HEIGHT))}%, queue #{available.size}"
      debug "avg sort time: #{times.avg}"
      debug "cores: #{cores}" if cores
      times = []
    end
  
    if available.size == 0
      best = opts[:start]
      best2 = best
    else
      # Find the best place from the list of available coordinates
      ##
      best = available.to_a
                      .group_by {|c| calc_diff_cache(caching[*c], color) }
      best = best[best.keys.min].sample :random => PRNG
      
      start = Time.now

      saatavillat = available.to_a

      avails = caching2[saatavillat.map {|(x, y)| x * WIDTH + y }, false]

      scores = calc_diff_vectorized(avails, color)
      puts "scores: #{scores.inspect}"
      poss   = scores <= scores.min
      puts "poss: #{poss.inspect}"
      ixs    = poss.to_a.each_index.select {|i| poss[i] == 1 }
      puts "ixs: #{ixs.inspect}"
      best2   = saatavillat[ixs.sample :random => PRNG]
      puts "best: #{best2.inspect}"
      
      times << (Time.now - start)
    end

    p best
    p best2
    best = best2

    # Put pixel where it belongs
    pixels[*best]   = color
    neighbs = Specific::available(best, caching, i + 1)
 
    [best, *neighbs].each do |coord|
      update_cache caching, coord, color
    end
  
    available.delete best


    neighbs2 = Specific::available(best2, caching, i + 1)
    neigh_ixs = [best2, *neighbs2].map do |coord|
      coord[0] * WIDTH + coord[1]
    end

    neighbors = caching2[neigh_ixs, false]
    update_cache_vec neighbors, color

    #available.delete best2

    # adjust available list
    neighbs.each do |neighbor|
      # don't overwrite pixels
      unless pixels[*neighbor]
        available << neighbor
      end
    end
  
    if checkpoints[i]
      debug "Checkpoint #{checkpoints[i]}"
      img = ChunkyPNG::Image.new WIDTH, HEIGHT, ChunkyPNG::Color::TRANSPARENT
  
      HEIGHT.times do |y|
        WIDTH.times do |x|
          rgb = pixels[x, y]
          if rgb
            img[x, y] = ChunkyPNG::Color.rgba rgb.R.to_i, rgb.G.to_i, rgb.B.to_i, 255
          end
        end
      end

      fname = "#{opts[:directory]}/checkpoint_#{run_id}_#{"%02d" % checkpoints[i]}.png"
      img.save fname
      debug "Wrote #{fname}"
    end
  
    i += 1
  end

  # Add a white border
  available.each do |coord|
    pixels[*coord] = RGB.new 255, 255, 255
  end

  # Print the final output to a fancy filename if desired
  unless opts[:output].empty?
    img = ChunkyPNG::Image.new WIDTH, HEIGHT, ChunkyPNG::Color::TRANSPARENT
    
    HEIGHT.times do |y|
      WIDTH.times do |x|
        rgb = pixels[x, y]
        if rgb
          img[x, y] = ChunkyPNG::Color.rgba rgb.R.to_i, rgb.G.to_i, rgb.B.to_i, 255
        end
      end
    end

    fname = File.join(opts[:directory], opts[:output])
    img.save fname
    debug "Wrote #{fname}"
  end

end

#require 'pry'
#binding.pry


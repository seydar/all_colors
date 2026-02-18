#!/usr/bin/env ruby --yjit
require 'fileutils'
require 'optimist'
require 'hsluv'
require_relative 'lib/monkey_patch.rb'
require_relative 'lib/color.rb'
require_relative 'lib/image.rb'
require_relative 'lib/neighbors.rb'
require_relative 'lib/sorting.rb'

PRNG = Random.new 783

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

HSLUV = opts[:hsluv] || Specific::HSLUV #true#false


if HSLUV
  colors = transform(colors, :to => :hsluv).sort_by {|c| c.vector.to_a }
else
  colors = colors.map {|c| RGB.new(*(c * 255).vector.map(&:round)) }
  colors = colors.sort_by {|rgb| rgb.hue }
end

colors = Specific::order colors


# Temporary place to do work instead of writing to bitmap
pixels  = Matrix.build(WIDTH, HEIGHT) {}

if HSLUV
  caching = Matrix.build(WIDTH, HEIGHT) { {:squares => 0.0, :sum => 0.0, :size => 0} }
else
  caching = Matrix.build(WIDTH, HEIGHT) { {:squares => 0.0, :sum => RGB.new(0.0, 0.0, 0.0), :size => 0, :first => 0.0, :middle => 0.0} }
end

available = Set.new

# calculate checkpoints in advance
num_checks  = opts[:checkpoints].to_i
checkpoints = (1..num_checks).map {|i| [i * colors.size / num_checks - 1, i - 1] }.to_h

profile :profile => opts[:profiling] do

  times = []

  # loop through all colors that we want to place
  colors.size.times do |i|
  #(1 * colors.size / 30).times do |i|
  #5.times do |i|
  
    # Debug
    if i % 512 == 0
      debug "#{"%0.4f" % (100.0 * i / (WIDTH * HEIGHT))}%, queue #{available.size}"
      debug "avg sort time: #{times.avg}"
      times = []
    end
  
    if available.size == 0
      best = opts[:start]
    else
      # Find the best place from the list of available coordinates
      # uses parallel processing, most expensive step
      if available.size > 30000 and opts[:parallel] > 0
        #best = available.parallel_min_by(:cores => opts[:parallel]) do |c|
        #  calc_diff_cache(pixels, caching, c, colors[i])
        #end
        start = Time.now
        #best = available.to_a.min_by {|c| calc_diff_cache(pixels, caching, c, colors[i]) }
        best = available.to_a
                .parallel_group_by(:cores => opts[:parallel]) {|c| calc_diff_cache(pixels, caching, c, colors[i]) }
        best = best[best.keys.min].sample :random => PRNG
        times << (Time.now - start)
      else
        # too small, don't parallelize it
        #sorted = available.to_a.sort_by {|c| calc_diff_cache(pixels, caching, c, colors[i]) }
        start = Time.now
        #best = available.to_a.min_by {|c| calc_diff_cache(pixels, caching, c, colors[i]) }
        best = available.to_a
                .group_by {|c| calc_diff_cache(pixels, caching, c, colors[i]) }
        best = best[best.keys.min].sample :random => PRNG
        times << (Time.now - start)
      end
      
      #sorted = available.sort_by {|c| calc_diff_cache(pixels, caching, c, colors[i]) }
      #best = available.to_a.min_by {|c| calc_diff_cache(pixels, caching, c, colors[i]) }
  
      #best = sorted[0]
    end

    #p(available.map {|c| [c, calc_diff_cache(pixels, caching, c, colors[i])] }.sort_by {|a, b| b })
    #p best
  
    # Put pixel where it belongs
    pixels[*best]   = colors[i]
    neighbs = Specific::available(best, caching, i + 1)

    [best, *neighbs].each do |coord|
      update_cache caching, coord, colors[i]
    end
  
    available.delete best

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
            img[x, y] = ChunkyPNG::Color.rgba rgb.R, rgb.G, rgb.B, 255
          end
        end
      end

      fname = "#{opts[:directory]}/checkpoint_#{run_id}_#{"%02d" % checkpoints[i]}.png"
      img.save fname
      debug "Wrote #{fname}"
    end
  
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
          img[x, y] = ChunkyPNG::Color.rgba rgb.R, rgb.G, rgb.B, 255
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


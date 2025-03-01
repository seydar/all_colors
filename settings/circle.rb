module Specific
  extend self

  HSLUV  = false
  filename = __FILE__.split("/").last.split(".")[0..-2].join(".")
  DIRECTORY = "output/#{filename}_#{HSLUV ? "hsluv" : "rgb"}"
  START  = [128, 64]
  SIZE   = [256, 128]
  COLORS = 32
  PROFILING = false

  def order(colors)
    #colors.shuffle :random => PRNG
    colors
  end

  # higher power = more watercolor (preference for filling in spaces)
  # lower power = more coral (preference for similar colors)
  def distance_weight(size)
    (9 - size) ** 5
  end

  def available(coord, caching, i)
    # a = pi * r ** 2
    # r = sqrt(a / pi)
    
    radius  = Math.sqrt(i.to_f / Math::PI).ceil

    circum = Set.new
    a, b = *coord
    (a - radius .. a + radius).each do |x|
      (b - radius .. b + radius).each do |y|
        circum << [x, y] if (x - a) ** 2 + (y - b) ** 2 <= radius ** 2
      end
    end

    circum.filter {|x, y| x < WIDTH && x >= 0 && y < HEIGHT && y >= 0 }
  end
end


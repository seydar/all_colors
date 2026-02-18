module Specific
  extend self

  HSLUV  = false
  filename = __FILE__.split("/").last.split(".")[0..-2].join(".")
  DIRECTORY = "output/#{filename}_#{HSLUV ? "hsluv" : "rgb"}"
  START  = [1500, 811]
  SIZE   = [4096, 4096]
  COLORS = 256
  PROFILING = false

  def available(coord, caching, i=nil)
    x, y   = *coord
    neighs = (x - 1..x + 1).to_a.product((y - 1..y + 1).to_a) - [x, y]
    neighs.filter {|x, y| x < WIDTH && x >= 0 && y < HEIGHT && y >= 0 }
  end

  def order(colors)
    #parts = colors.each_slice(colors.size / 12).to_a

    #colors = parts[0..1] +
    #         parts[5..6] +
    #         parts[10..11] +
    #         parts[2..4] +
    #         parts[7..9]
    #colors.flatten
    colors
  end

  # higher power = more watercolor (preference for filling in spaces)
  # lower power = more coral (preference for similar colors)
  def distance_weight(size)
    (9 - size)
  end
end


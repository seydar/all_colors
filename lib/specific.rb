module Specific
  extend self

  OUTPUT = "output/test"
  START  = [128, 64]
  SIZE   = [256, 128]
  COLORS = 32
  HSLUV  = false
  PROFILING = false

  def order(colors)
    colors
  end

  def distance_weight(size)
    1
  end

  def available(coord, i=nil)
    x, y   = *coord
    neighs = (x - 1..x + 1).to_a.product((y - 1..y + 1).to_a) - [x, y]
    neighs.filter {|x, y| x < WIDTH && x >= 0 && y < HEIGHT && y >= 0 }
  end
end


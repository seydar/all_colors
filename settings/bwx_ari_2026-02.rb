module Specific
  extend self

  HSLUV  = false
  filename = __FILE__.split("/").last.split(".")[0..-2].join(".")
  DIRECTORY = "output/#{filename}_#{HSLUV ? "hsluv" : "rgb"}_contrast"
  START  = [85, 511]
  SIZE   = [875, 512]
  COLORS = 64
  PROFILING = false

  def available(coord, caching, i=nil)
    x, y   = *coord
    neighs = (x - 1..x + 1).to_a.product((y - 1..y + 1).to_a) - [x, y]
    neighs.filter {|x, y| x < WIDTH && x >= 0 && y < HEIGHT && y >= 0 }
  end

  def order(colors)
    # HSP color model
    #colors.sort_by {|c| Math.sqrt(0.299 * c.R ** 2 + 0.587 * c.G ** 2 + 0.114 * c.B ** 2) }

    # Contrast ratio
    colors.each_slice(colors.size / 4).map do |cs|
      cs.sort {|c1, c2| contrast_ratio c1, c2 }
    end.flatten.reverse
    
    #colors.sort {|c1, c2| contrast_ratio c1, c2 }

    #colors.each_slice(colors.size / 12).to_a.shuffle.flatten

    #parts = colors.each_slice(colors.size / 12).to_a

    #colors = parts[0..3] +
    #         parts[8..11] +
    #         parts[4..7]
    #colors.flatten
  end

  # higher power = more watercolor (preference for filling in spaces)
  # lower power = more coral (preference for similar colors)
  def distance_weight(size)
    (9 - size)
  end

  def contrast_ratio(c1, c2)
    l_1, l_2 = [c1.relative_luminance, c2.relative_luminance].sort

    (l_1 + 0.05) / (l_2 + 0.05)
  end
end


module Specific
  extend self

  HSLUV  = false
  filename = __FILE__.split("/").last.split(".")[0..-2].join(".")
  DIRECTORY = "output/#{filename}_#{HSLUV ? "hsluv" : "rgb"}"
  START  = [300, 60]
  SIZE   = [1200, 240]
  COLORS = 64

  def order(colors)
    colors[colors.size / 3 .. -1] + colors[0 .. colors.size / 3]
  end

  # higher power = more watercolor (preference for filling in spaces)
  # lower power = more coral (preference for similar colors)
  def distance_weight(size)
    (9 - size) ** 2
  end
end


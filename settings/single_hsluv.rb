module Specific
  extend self

  filename = __FILE__.split("/").last.split(".")[0..-2].join(".")
  OUTPUT = "output/#{filename}"
  START  = [64, 64]
  SIZE   = [256, 128]
  COLORS = 32
  HSLUV  = true

  def order(colors)
    colors[colors.size / 3..-1] + colors[0..colors.size / 3]
  end

  def distance_weight(size)
    1
  end
end


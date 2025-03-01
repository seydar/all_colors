module Specific
  extend self

  filename = __FILE__.split("/").last.split(".")[0..-2].join(".")
  DIRECTORY = "output/#{filename}_rgb"
  START  = [64, 64]
  SIZE   = [256, 128]
  COLORS = 32
  HSLUV  = true

  def order(colors)
    colors.shuffle :random => PRNG
  end

  def distance_weight(size)
    1
  end
end


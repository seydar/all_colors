module Specific
  extend self

  filename = __FILE__.split("/").last.split(".")[0..-2].join(".")
  DIRECTORY = "output/#{filename}"
  START  = [64, 64]
  SIZE   = [512, 256]
  COLORS = 64
  HSLUV  = true

  def order(colors)
    colors.partition.with_index {|c, i| i.even? }.flatten
  end

  def distance_weight(size)
    1
  end
end


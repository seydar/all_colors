module Specific
  extend self

  filename = __FILE__.split("/").last.split(".")[0..-2].join(".")
  OUTPUT = "output/#{filename}"
  START  = [0, 255]
  SIZE   = [512, 256]
  COLORS = 48
  HSLUV  = false

  def order(colors)
    #colors.partition.with_index {|c, i| i.even? }.flatten
    colors
  end

  def distance_weight(size)
    1
  end
end


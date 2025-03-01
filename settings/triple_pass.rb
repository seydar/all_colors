module Specific
  extend self

  HSLUV  = false
  filename = __FILE__.split("/").last.split(".")[0..-2].join(".")
  DIRECTORY = "output/#{filename}_#{HSLUV ? "hsluv" : "rgb"}"
  START  = [256, 127]
  SIZE   = [512, 256]
  COLORS = 32

  def order(colors)
    colors.group_by.with_index {|c, i| i % 3 }.to_a.sort_by {|k, v| k }.map(&:last).flatten
  end

  def distance_weight(size)
    1
  end
end


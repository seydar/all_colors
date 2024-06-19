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
end


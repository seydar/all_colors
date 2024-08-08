module Specific
  extend self

  HSLUV  = false
  filename = __FILE__.split("/").last.split(".")[0..-2].join(".")
  OUTPUT = "output/#{filename}_#{HSLUV ? "hsluv" : "rgb"}"
  START  = [150, 350]
  SIZE   = [875, 512]
  COLORS = 32
  PROFILING = false

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
    (9 - size) ** 1.5
  end
end


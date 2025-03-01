module Specific
  extend self

  HSLUV  = false
  filename = __FILE__.split("/").last.split(".")[0..-2].join(".")
  DIRECTORY = "output/#{filename}_#{HSLUV ? "hsluv" : "rgb"}"
  START  = [0, 64]
  SIZE   = [256, 128]
  COLORS = 32
  PROFILING = false#true

  def order(colors)
    #parts = colors.each_slice(colors.size / 12).to_a

    #colors = parts[0..1] +
    #         parts[5..6] +
    #         parts[10..11] +
    #         parts[2..4] +
    #         parts[7..9]
    #colors.flatten
    #colors.shuffle :random => PRNG
    colors
  end

  # higher power = more watercolor (preference for filling in spaces)
  # lower power = more coral (preference for similar colors)
  def distance_weight(size)
    (9 - size)
  end
end


module Specific
  extend self

  HSLUV  = false
  filename = __FILE__.split("/").last.split(".")[0..-2].join(".")
  DIRECTORY = "output/#{filename}_#{HSLUV ? "hsluv" : "rgb"}"
  START  = [150, 400]
  SIZE   = [512, 512]
  COLORS = 36
  PROFILING = false

  ORANGE_ICECREAM = ["#C024C0",
                     "#FF2397",
                     "#FF5A70",
                     "#FF9453",
                     "#FFC94F",
                     "#F9F871"]

  PASTEL = ["#fbf8cc",
            "#fde4cf",
            "#ffcfd2",
            "#f1c0e8",
            "#cfbaf0",
            "#a3c4f3",
            "#90dbf4",
            "#8eecf5",
            "#98f5e1",
            "#b9fbc0"]

  GREEN_ORANGE = ["#54478c",
                  "#2c699a",
                  "#048ba8",
                  "#0db39e",
                  "#16db93",
                  "#83e377",
                  "#b9e769",
                  "#efea5a",
                  "#f1c453",
                  "#f29e4c"]

  PALETTE = GREEN_ORANGE + ORANGE_ICECREAM

  def available(coord, caching, i=nil)
    x, y   = *coord
    neighs = (x - 1..x + 1).to_a.product((y - 1..y + 1).to_a) - [x, y]
    neighs.filter {|x, y| x < WIDTH && x >= 0 && y < HEIGHT && y >= 0 }
  end

  def order(colors)
    colors = colors.map do |c|
      hexes = PALETTE.sample.match(/^#(..)(..)(..)$/).captures.map(&:hex)
      RGB.new *hexes
    end.sort_by {|rgb| rgb.hue }

    #parts = colors.each_slice(colors.size / 2).to_a
    #parts.shuffle.flatten
  end

  # higher power = more watercolor (preference for filling in spaces)
  # lower power = more coral (preference for similar colors)
  def distance_weight(size)
    size
  end
end


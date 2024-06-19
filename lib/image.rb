require 'chunky_png'
require 'matrix'

def neighbors(coord)
  x, y   = *coord
  neighs = (x - 1..x + 1).to_a.product((y - 1..y + 1).to_a) - [x, y]
  neighs.filter {|x, y| x < WIDTH && x >= 0 && y < HEIGHT && y >= 0 }
end

def remove_coral(pixels)
  pxls = pixels.clone

  WIDTH.times do |x|
    next if x == 0 or x == WIDTH

    HEIGHT.times do |y|
      next if y == 0 or y == HEIGHT

      if pixels[x - 1, y] == nil && pixels[x + 1, y] == nil
        pxls[x, y] = nil
      end

      if pixels[x, y - 1] == nil && pixels[x, y + 1] == nil
        pxls[x, y] = nil
      end
    end
  end

  pxls
end


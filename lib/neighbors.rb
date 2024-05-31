# When placing a color, place it in the location where the average color
# differential from its neighbors is the minimum
#
# I'm not able to get much more than 60% CPU out of this. I should investigate
# vectorizing this somehow (not sure how)
def calc_diff(pixels, coord, c)
  diffs = []
  neighbors(coord).each do |n|
    nc = pixels[*n]
    if nc
      diffs << (nc - c).mag_2 if nc
    end
  end

  diffs.avg# * (9 - diffs.size) ** 2
  #diffs.min
end

def calc_diff_long(pixels, caching, coord, c)
  sum = []
  sqs = []
  neighbors(coord).each do |n|
    nc = pixels[*n]
    if nc
      sum << nc
      sqs << (nc * nc)
    end
  end

  first  = sqs.avg
  middle = -1 * (c * sum.inject {|s, v| s + v } * 2 / sum.size)
  last   = (c * c)

  p [first, middle, last]
  first + middle + last
end

def calc_diff_cache(pixels, caching, coord, c)
  hash   = caching[*coord]
  size   = [1, hash[:size]].max

  first  = hash[:squares] / size
  middle = -1 * (c * hash[:sum] * 2 / size)
  last   = (c * c)

  p [first, middle, last]
  first + middle + last
end

def update_cache(caching, coord, c)
  hash = caching[*coord]
  hash[:squares] += (c * c)
  hash[:sum]     += c.vector
  hash[:size]    += 1
end



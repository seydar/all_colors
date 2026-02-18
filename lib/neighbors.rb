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
      diffs << (nc - c).mag_2
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

  first + middle + last
end

#def calc_diff_cache(pixels, caching, coord, c)
#  hash   = caching[*coord]
#
#  first  = hash[:squares]
#  middle = -1 * (c * hash[:sum] * 2)
#  last   = (c * c)
#
#  (first + middle + last) * (9 - hash[:size]) ** 7
#end
#
#def update_cache(caching, coord, c)
#  hash = caching[*coord]
#  hash[:size]    += 1
#  hash[:squares]  = hash[:squares] * (hash[:size] - 1) / hash[:size] + (c * c) / hash[:size]
#  hash[:sum]     += hash[:sum] * (hash[:size] - 1) / hash[:size] + c.vector / hash[:size]
#end

# This is smooth, the above is not, for some reason
def calc_diff_cache(pixels, caching, coord, c)
  c = c.hue if HSLUV
  hash   = caching[*coord]

  return 0.0 if hash[:size] == 0

  #first  = hash[:squares] / hash[:size]
  #middle = -1 * (c * hash[:sum] * 2 / hash[:size])
  #last   = c.sq

  first  = hash[:first]
  middle = c * hash[:middle]
  last   = c.sq

  #(first + middle + last) * Specific::distance_weight(hash[:size])
  val = first + (middle + last) * Specific::distance_weight(hash[:size])
  hash[:size] > 4 ? val - hash[:size] : val
end

def update_cache(caching, coord, c)
  if HSLUV
    c = c.hue
    hash = caching[*coord]
    hash[:squares] += c.sq
    hash[:sum]     += c
    hash[:size]    += 1
    hash[:first]    = Specific::distance_weight(hash[:size]) * hash[:squares] / hash[:size]
    hash[:middle]   = -1 * hash[:sum] * 2 / hash[:size]
  else
    hash = caching[*coord]
    hash[:squares] += c.sq
    hash[:sum]     += c#.vector
    hash[:size]    += 1
    hash[:first]    = Specific::distance_weight(hash[:size]) * hash[:squares] / hash[:size]
    hash[:middle]   = (hash[:sum] * 2 / hash[:size]) * -1
  end
end



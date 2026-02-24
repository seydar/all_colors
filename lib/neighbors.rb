# When placing a color, place it in the location where the average color
# differential from its neighbors is the minimum

def calc_diff_cache(hash, c)
  size, first, middle = *hash[:details]
  return 0.0 if size == 0

  middle = c * middle
  last   = c.sq

  val = first + (middle + last) * Specific::distance_weight(size)
  size > 4 ? val - size : val # what the fuck is happening with this line
end

def calc_diff_vectorized(avails, c)
  size  = avails[false, 0]
  first = avails[false, 5]
  mid_r = avails[false, 6]
  mid_g = avails[false, 7]
  mid_b = avails[false, 8]

  middle = c.R * mid_r + c.G * mid_g + c.B * mid_b
  last   = c.sq

  val = first + (middle + last) * Specific::distance_weight(size)
  val - size
end

def update_cache(caching, coord, c)
  c = c.hue if HSLUV
  hash = caching[*coord]
  hash[:squares] += c.sq
  hash[:sum]     += c#.vector
  hash[:size]    += 1
  first           = Specific::distance_weight(hash[:size]) * hash[:squares] / hash[:size]
  middle          = (hash[:sum] * 2 / hash[:size]) * -1
  hash[:details]  = [hash[:size], first, middle]
end

# size, squares, sum(r), sum(g), sum(b), first, middle(r), middle(g), middle(b)
def update_cache_vec(neighbors, c)
  neighbors[false, 0] += 1
  neighbors[false, 1] += c.sq

  size = neighbors[false, 0]
  sqs  = neighbors[false, 1]

  neighbors[false, 2] += c.R
  neighbors[false, 3] += c.G
  neighbors[false, 4] += c.B

  neighbors[false, 5]  = Specific::distance_weight(size) * sqs / size

  neighbors[false, 6]  = -2 * neighbors[false, 2] / size
  neighbors[false, 7]  = -2 * neighbors[false, 3] / size
  neighbors[false, 8]  = -2 * neighbors[false, 4] / size

end



class RGB
  attr_accessor :vector

  def initialize(r, g, b)
    #@vector = Vector[r, g, b]
    @vector = [r, g, b]
  end

  def R; @vector[0]; end
  def G; @vector[1]; end
  def B; @vector[2]; end

  def +(o)
    case o
    when RGB
      #RGB.new(*(@vector + o.vector))
      RGB.new self.R + o.R,
              self.G + o.G,
              self.B + o.B
    else
      #RGB.new(*(@vector + o))
      RGB.new self.R + o,
              self.G + o,
              self.B + o
    end
  end

  def -(o)
    case o
    when RGB
      #RGB.new(*(@vector - o.vector))
      RGB.new self.R - o.R,
              self.G - o.G,
              self.B - o.B
    else
      #RGB.new(*(@vector - o))
      RGB.new self.R - o,
              self.G - o,
              self.B - o
    end
  end

  def *(o)
    case o
    when RGB
      #@vector.inner_product(o.vector)
      #self.vector.zip(o.vector).map {|a, b| a + b }.sum
      ip o
    else
      #RGB.new(*(@vector * o))
      RGB.new self.R * o,
              self.G * o,
              self.B * o
    end
  end

  def ip(o)
    self.R * o.R +
    self.G * o.G +
    self.B * o.B
  end

  def mag_2
    @mag_2 ||= self.R * self.R + self.G * self.G + self.B * self.B
  end
  alias_method :sq, :mag_2

  def /(o)
    case o
    when RGB
      RGB.new(*(@vector / o.vector))
    else
      #RGB.new(*(@vector / o))
      RGB.new self.R / o,
              self.G / o,
              self.B / o
    end
  end

  def hue
    max = [self.R, self.G, self.B].max.to_f
    min = [self.R, self.G, self.B].min.to_f

    return 0.0 if max == min

    hue = case max
          when self.R
            (self.G - self.B) / (max - min)
          when self.G
            2.0 + (self.B - self.R) / (max - min)
          when self.B
            4.0 + (self.R - self.G) / (max - min)
          end

    # commented out because this is only used for ordering, so we don't need these
    # affine transformations

    #if hue * 60 < 0
    #  hue * 60 + 360
    #else
    #  hue * 60
    #end
  end
end




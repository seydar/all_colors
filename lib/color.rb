require 'numo/narray'

class RGB
  attr_accessor :vector

  def initialize(r, g, b)
    @vector = Numo::NArray[r, g, b]
    #@vector = [r, g, b]
    @r = r.to_i
    @g = g.to_i
    @b = b.to_i
  end

  def R; @r; end
  def G; @g; end
  def B; @b; end

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
      @vector.inner(o.vector)
      #ip o
    else
      #RGB.new(*(@vector * o))
      RGB.new self.R * o,
              self.G * o,
              self.B * o
    end
  end

  # inner product
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

  def relative_luminance
    return @rel_lum if @rel_lum

    r = self.R / 255.0
    g = self.G / 255.0
    b = self.B / 255.0

    # some sources use 0.04045 as the dividing line instead of 0.03928
    r = r <= 0.03928 ? r / 12.92 : ((r + 0.055) / 1.055) ** 2.4
    g = g <= 0.03928 ? g / 12.92 : ((g + 0.055) / 1.055) ** 2.4
    b = b <= 0.03928 ? b / 12.92 : ((b + 0.055) / 1.055) ** 2.4

    @rel_lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
  end

  # perceived lightness
  def l_star
    y = relative_luminance

    if y <= 0.008856
      y * 903.3
    else
      y ** (1/3.0) * 116 - 16
    end
  end

  def chromaticity
    [self.R / (255 * 3.0), self.G / (255 * 3.0), self.B / (255 * 3.0)]
  end

  def Z
    self.B
  end

  
end




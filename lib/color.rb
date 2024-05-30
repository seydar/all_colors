RGB = Struct.new :R, :G, :B do
  def +(o)
    RGB.new(self.R + o.R,
            self.G + o.G,
            self.B + o.B)
  end

  def -(o)
    RGB.new(self.R - o.R,
            self.G - o.G,
            self.B - o.B)
  end

  def *(scalar)
    RGB.new(self.R * scalar,
            self.G * scalar,
            self.B * scalar)
  end

  def /(scalar)
    RGB.new(self.R / scalar,
            self.G / scalar,
            self.B / scalar)
  end

  def mag
    Math.sqrt(mag_2)
  end

  def mag_2
    self.R ** 2 + self.G ** 2 + self.B ** 2
  end

  def sq
    RGB.new(self.R ** 2,
            self.G ** 2,
            self.B ** 2)
  end

  def manhattan
    self.R + self.G + self.B
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


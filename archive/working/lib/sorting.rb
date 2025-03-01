def transform(colors, to: :rgb)
  case to
  when :rgb
    colors.map {|c| RGB.new *Hsluv.hsluv_to_rgb(*c) }
  when :hsluv
    colors.map {|c| RGB.new *Hsluv.rgb_to_hsluv(c.R, c.G, c.B) }
  end
end


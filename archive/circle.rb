
      #if checkpoints[i] == 29

      #  open("final.marshal", "w") {|f| f.write Marshal.dump(pixels) }

      #  # Create circular streaks and then blank them out
      #  margin = 5
      #  0.step(:to => opts[:size].max, :by => 10) do |radius|
      #    circum = Set.new
      #    a, b = *opts[:start]
      #    (a - radius - 2 *margin .. a + radius + 2 * margin).each do |x|
      #      (b - radius - 2 * margin .. b + radius + 2 * margin).each do |y|
      #        if (x - a) ** 2 + (y - b) ** 2 <= ((radius + margin) ** 2) &&
      #           (x - a) ** 2 + (y - b) ** 2 >= ((radius - margin) ** 2)
      #          circum << [x, y]
      #        end
      #      end
      #    end

      #    # pick a random starting point, and delete part of it
      #    circum = circum.to_a
      #    circum = circum.rotate(rand(circum.size))[0, 3 * circum.size / 4]

      #    # blank them out
      #    circum = circum.filter {|x, y| x < WIDTH && x >= 0 && y < HEIGHT && y >= 0 }
      #    circum.each {|pt| img[*pt] = ChunkyPNG::Color.rgba(0, 0, 0, 0) }
      #  end
      #end

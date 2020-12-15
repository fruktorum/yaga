def simulate( population : YAGA::Population, data : Data, best_bot : YAGA::Bot ) : Void
	population.simulate_each{|bot|
		result = Array( BitArray ).new( 16 ){ BitArray.new 2 }

		data.inputs.each_with_index{|input, input_index|
			bot.activate( input ).each_with_index{|value, index|
				result[ input_index ][ index ] = value
			}
		}

		print "\e[0;32m" if bot.same? best_bot
		p result: result.map( &.to_a.map{ |value| value ? 1_u8 : 0_u8 } )
		print "\e[0m" if bot.same? best_bot
	}
end

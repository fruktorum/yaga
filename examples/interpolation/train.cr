def train( population : YAGA::Population, simulations : UInt64 ) : Void
	population.train_world( 1, simulations ){|bots|
		listeners = Array( Channel( Nil ) ).new( 4 ){ Channel( Nil ).new }

		[
			0_u16 .. bots.size // 4 - 1_u16,
			bots.size // 4 .. bots.size // 2 - 1_u16,
			bots.size // 2 .. 3_u16 * bots.size // 4 - 1_u16,
			3_u16 * bots.size // 4 .. bots.size - 1_u16
		].each_with_index{|range, listener_index|
			spawn do
				range.each{|bot_index|
					mse = BigFloat.new 0
					bot = bots[ bot_index ]

					activation_zero = bot.activate( [ 0_i64 ] ).first
					activation_one = bot.activate( [ 1_i64 ] ).first
					mse += ( activation_zero ** 2 + activation_one ** 2 + ( bot.genome.dna.first.first.evaluate( 0.5 ) - 0.5 ) ** 2 ) / 3

					bot.fitness = ( 1 / ( mse + 1 ) ).to_f64
				}

				listeners[ listener_index ].send nil
			end
		}

		listeners.each &.receive
	}

	puts
end

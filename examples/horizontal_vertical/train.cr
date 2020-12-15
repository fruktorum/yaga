module Training

	ACTIVATIONS = BitArray.new 16

	def self.train_each( population : YAGA::Population, simulations : UInt64, inputs : Array( BitArray ), outputs : Array( BitArray ), log : Bool = false ) : UInt64
		unless log
			bar = ProgressBar.new( ( simulations * population.total_bots ).to_i )
			bar.incomplete = "-"
			bar.complete = "#"
			bar.width = 50
		end

		training_result = population.train_each( 16, simulations ){|bot|
			fitness = 0_u8

			inputs.each_with_index{|input, index|
				activation = bot.activate input
				fitness += 1 if activation == outputs[ index ]
				ACTIVATIONS[ index ] = activation[ 0 ]
			}

			if log
				p activations: ACTIVATIONS, fitness: fitness, genes: bot.to_json
			else
				bar.not_nil!.inc
			end

			fitness
		}

		bar.not_nil!.print unless log

		training_result
	end

	def self.train_world( population : YAGA::Population, simulations : UInt64, inputs : Array( BitArray ), outputs : Array( BitArray ), log : Bool = false ) : UInt64
		unless log
			bar = ProgressBar.new simulations.to_i
			bar.incomplete = "-"
			bar.complete = "#"
			bar.width = 50
		end

		training_result = population.train_world( 16, simulations ){|bots|
			run_simulation bots, inputs, outputs, log
			bar.not_nil!.inc unless log
		}

		bar.not_nil!.print unless log

		training_result
	end

	private def self.run_simulation( bots : Array( YAGA::Bot ), inputs : Array( BitArray ), outputs : Array( BitArray ), log : Bool ) : Void
		bots.each{|bot|
			fitness = 0_u8

			inputs.each_with_index{|input, index|
				activation = bot.activate input # Last genome layer calculation result
				fitness += 1 if activation == outputs[ index ] # Calculate fitness
				ACTIVATIONS[ index ] = activation[ 0 ]
			}

			bot.fitness = fitness

			p activations: ACTIVATIONS, fitness: fitness, genes: bot.to_json if log
		}
	end

end

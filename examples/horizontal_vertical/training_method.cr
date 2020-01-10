class Data

	def train( population : YAGA::Population, simulations : UInt64, log : Bool = false ) : UInt64
		unless log
			bar = ProgressBar.new( ( simulations * population.total_bots ).to_i )
			bar.incomplete = "-"
			bar.complete = "#"
			bar.width = 50
		end

		training_result = population.train( 15.9, simulations ){|bot|
			fitness = 0_f64

			@inputs.each_with_index{|input, index|
				activation = bot.activate input
				fitness += 1 if activation == @outputs[ index ]
				@activations[ index ] = activation[ 0 ]
			}

			if log
				p activations: @activations, fitness: fitness, genes: bot.genome.genes
			else
				bar.not_nil!.inc
			end

			fitness
		}

		bar.not_nil!.print unless log

		training_result
	end

end

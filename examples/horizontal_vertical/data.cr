class Data
	getter inputs, outputs

	@inputs : Array( BitArray )
	@outputs : Array( BitArray )

	def initialize
		@inputs = Array( BitArray ).new( 16 ){ BitArray.new 9 }
		@outputs = Array( BitArray ).new( 16 ){ BitArray.new 2 }
		@activations = BitArray.new 16

		fill_inputs
		fill_outputs
	end

	def train( population : YAGA::Population, simulations : UInt64, log : Bool = false ) : UInt64
		unless log
			bar = ProgressBar.new( ( simulations * population.total_bots ).to_i )
			bar.incomplete = "-"
			bar.complete = "#"
			bar.width = 50
		end

		training_result = population.train_each( 16_f64, simulations ){|bot|
			fitness = 0_f64

			@inputs.each_with_index{|input, index|
				activation = bot.activate input
				fitness += 1 if activation == @outputs[ index ]
				@activations[ index ] = activation[ 0 ]
			}

			if log
				p activations: @activations, fitness: fitness, genes: bot.genome.dna
			else
				bar.not_nil!.inc
			end

			fitness
		}

		bar.not_nil!.print unless log

		training_result
	end

	private def fill_inputs : Void
		%w[ 1 1 1 0 0 0 0 0 0 ].each_with_index{ |value, index| @inputs[ 0 ][ index ] = value == "1" }
		%w[ 0 1 0 0 1 0 0 1 0 ].each_with_index{ |value, index| @inputs[ 1 ][ index ] = value == "1" }
		%w[ 1 1 1 0 0 1 0 0 1 ].each_with_index{ |value, index| @inputs[ 2 ][ index ] = value == "1" }
		%w[ 1 0 0 1 0 0 1 1 1 ].each_with_index{ |value, index| @inputs[ 3 ][ index ] = value == "1" }
		%w[ 0 0 0 1 1 1 0 0 0 ].each_with_index{ |value, index| @inputs[ 4 ][ index ] = value == "1" }
		%w[ 0 0 1 0 0 1 0 0 1 ].each_with_index{ |value, index| @inputs[ 5 ][ index ] = value == "1" }
		%w[ 1 0 0 1 1 1 1 0 0 ].each_with_index{ |value, index| @inputs[ 6 ][ index ] = value == "1" }
		%w[ 0 1 0 0 1 0 1 1 1 ].each_with_index{ |value, index| @inputs[ 7 ][ index ] = value == "1" }
		%w[ 0 0 0 0 0 0 1 1 1 ].each_with_index{ |value, index| @inputs[ 8 ][ index ] = value == "1" }
		%w[ 1 1 1 1 0 0 1 0 0 ].each_with_index{ |value, index| @inputs[ 9 ][ index ] = value == "1" }
		%w[ 0 1 0 1 1 1 0 1 0 ].each_with_index{ |value, index| @inputs[ 10 ][ index ] = value == "1" }
		%w[ 0 0 1 0 0 1 1 1 1 ].each_with_index{ |value, index| @inputs[ 11 ][ index ] = value == "1" }
		%w[ 1 0 0 1 0 0 1 0 0 ].each_with_index{ |value, index| @inputs[ 12 ][ index ] = value == "1" }
		%w[ 1 1 1 0 1 0 0 1 0 ].each_with_index{ |value, index| @inputs[ 13 ][ index ] = value == "1" }
		%w[ 0 0 1 1 1 1 0 0 1 ].each_with_index{ |value, index| @inputs[ 14 ][ index ] = value == "1" }
		%w[ 0 0 0 0 0 0 0 0 0 ].each_with_index{ |value, index| @inputs[ 15 ][ index ] = value == "1" }
	end

	private def fill_outputs : Void
		%w[ 1 0 ].each_with_index{ |value, index| @outputs[ 0 ][ index ] = value == "1" }
		%w[ 0 1 ].each_with_index{ |value, index| @outputs[ 1 ][ index ] = value == "1" }
		%w[ 1 1 ].each_with_index{ |value, index| @outputs[ 2 ][ index ] = value == "1" }
		%w[ 1 1 ].each_with_index{ |value, index| @outputs[ 3 ][ index ] = value == "1" }
		%w[ 1 0 ].each_with_index{ |value, index| @outputs[ 4 ][ index ] = value == "1" }
		%w[ 0 1 ].each_with_index{ |value, index| @outputs[ 5 ][ index ] = value == "1" }
		%w[ 1 1 ].each_with_index{ |value, index| @outputs[ 6 ][ index ] = value == "1" }
		%w[ 1 1 ].each_with_index{ |value, index| @outputs[ 7 ][ index ] = value == "1" }
		%w[ 1 0 ].each_with_index{ |value, index| @outputs[ 8 ][ index ] = value == "1" }
		%w[ 1 1 ].each_with_index{ |value, index| @outputs[ 9 ][ index ] = value == "1" }
		%w[ 1 1 ].each_with_index{ |value, index| @outputs[ 10 ][ index ] = value == "1" }
		%w[ 1 1 ].each_with_index{ |value, index| @outputs[ 11 ][ index ] = value == "1" }
		%w[ 0 1 ].each_with_index{ |value, index| @outputs[ 12 ][ index ] = value == "1" }
		%w[ 1 1 ].each_with_index{ |value, index| @outputs[ 13 ][ index ] = value == "1" }
		%w[ 1 1 ].each_with_index{ |value, index| @outputs[ 14 ][ index ] = value == "1" }
		%w[ 0 0 ].each_with_index{ |value, index| @outputs[ 15 ][ index ] = value == "1" }
	end
end

class Data
	@population : YAGA::Population( QuadraticGenome )
	@inputs : Array( UInt16 )
	@outputs : Array( Int64 )
	@bar : ProgressBar

	def initialize( @population, @inputs, @outputs )
		@bar = ProgressBar.new width: 50, complete: "#", incomplete: "-"
	end

	def train( simulations_cap : UInt64, log : Bool = false ) : UInt64
		@bar.total = ( simulations_cap * @population.total_bots ).to_i
		max_mse = BigFloat.new 0

		training_result = @population.train( 1, simulations_cap ){|bot|
			mse = BigFloat.new 0

			@inputs.each_with_index{|input, index|
				output = @outputs[ index ]

				activation = bot.activate( [ input ] )[ 0 ]
				mse += ( ( output - activation ).to_big_f ** 2 ) / @inputs.size

				p input: input, prediction: activation, actual: output, diff: output - activation, mse: mse, genome: bot.genome.chromosome_layers.map( &.map( &.genes ) ) if log
			}

			max_mse = mse if max_mse < mse

			@bar.inc unless log

			# MSE = sum( ( actual - output ) ** 2 )
			# But we need a fitness of the bot that can be presented like 1 / MSE
			# Because MSE can be 0, add 1 to denominator to prevent division by zero
			( 1 / ( mse + 1 ) ).to_f64
		}

		@bar.print unless log
		puts
		p max_mse: max_mse

		training_result
	end

	def self.f( x : UInt16 ) : Int64
		x.to_i64 ** 2_i64 - 5_i64 * x.to_i64 + 2_i64
	end
end

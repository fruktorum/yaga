module Training

	BAR = ProgressBar.new width: 50, complete: "#", incomplete: "-"

	def self.train( population : YAGA::Population, data : Data, simulations_cap : UInt64, log : Bool = false ) : UInt64
		BAR.total = ( simulations_cap * population.total_bots ).to_i
		BAR.set 0

		max_mse = BigFloat.new 0

		training_result = population.train_each( 1, simulations_cap ){|bot|
			mse = BigFloat.new 0

			data.inputs.each_with_index{|input, index|
				output = data.outputs[ index ]

				activation = bot.activate( [ input ] ).first
				mse += ( ( output - activation ).to_big_f ** 2 ) / data.inputs.size

				p input: input, prediction: activation, actual: output, diff: output - activation, mse: mse, genome: bot.to_json if log
			}

			max_mse = mse if max_mse < mse

			BAR.inc unless log

			# MSE = sum( ( actual - output ) ** 2 )
			# But we need a fitness of the bot that can be presented like 1 / MSE
			# Because MSE can be 0, add 1 to denominator to prevent division by zero
			( 1 / ( mse + 1 ) ).to_f64
		}

		BAR.print unless log
		puts
		p max_mse: max_mse

		training_result
	end

end

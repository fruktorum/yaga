class ParamsChromosome
	include YAGA::Chromosome( Array( Int64 ), Array( Int64 ), BigFloat )

	COEFFICIENTS_RANGE = -75_i64 .. 75_i64
	LAST_COEFFICIENT_RANGE = 1_i64 .. 75_i64

	def initialize( @num_inputs, @layer_index, @chromosome_index )
		# Coefficients up to power of 12
		# Uncomment when it will be needed
		#
		# @power = 12
		# @derivative_coefficients = [
		# 	[ 12, 11, 10, 9, 8, 7, 6, 5, 4 ],
		# 	[ 132, 110, 90, 72, 56, 42, 30, 20, 12 ],
		# 	[ 1320, 990, 720, 504, 336, 210, 120, 60, 24 ]
		# ]

		@power = 8
		@derivative_coefficients = [
			[ 8, 7, 6, 5, 4 ],
			[ 56, 42, 30, 20, 12 ],
			[ 336, 210, 120, 60, 24 ]
		]

		genes_size = @power - @derivative_coefficients.size
		@genes = T.new( genes_size ){ |index| @random.rand index < genes_size - 1 ? COEFFICIENTS_RANGE : LAST_COEFFICIENT_RANGE }
	end

	def activate( inputs : U ) : V
		mse = BigFloat.new 0

		@derivative_coefficients.each_with_index{|derivative, derivative_index|
			result = 0_i64

			@genes.each_with_index{|multiplier, coefficient_index|
				coefficient = multiplier * derivative[ coefficient_index ]
				exponent = @power - coefficient_index - derivative_index - 1
				result += coefficient * ( inputs.first ** exponent )
			}

			mse += ( result.to_big_f ** 2 ) / @derivative_coefficients.size
		}

		mse
	end

	def evaluate( x : Float64 ) : Float64
		result = 0_f64
		@genes.each_with_index{ |gene, index| result += gene * ( x ** ( @power - index ) ) }
		result
	end

	def activate_derivative( value : Int64, derivative_index : UInt32 ) : Int64
		result = 0_i64

		@genes.each_with_index{|multiplier, coefficient_index|
			coefficient = multiplier * @derivative_coefficients[ derivative_index ][ coefficient_index ]
			exponent = @power - coefficient_index - derivative_index - 1
			result += coefficient * ( value ** exponent )
		}

		result
	end

	def randomize : Void
		genes_size = @power - @derivative_coefficients.size
		@genes = T.new( genes_size ){ |index| @random.rand index < genes_size - 1 ? COEFFICIENTS_RANGE : LAST_COEFFICIENT_RANGE }
	end

	def mutate : Void
		index = @random.rand @genes.size
		@genes[ index ] = @random.rand index < @genes.size - 1 ? COEFFICIENTS_RANGE : LAST_COEFFICIENT_RANGE
	end

	def replace( other : YAGA::Chromosome ) : Void
		other_genes = other.genes.as T
		@genes.each_index{ |index| @genes[ index ] = other_genes[ index ] }
	end

	def crossover( other : YAGA::Chromosome ) : Void
		other_genes = other.genes.as T

		slice = @random.rand @genes.size
		left = @random.rand( 2_u8 ) == 0

		@genes.each_index{ |index| @genes[ index ] = index <= slice ? ( left ? @genes[ index ] : other_genes[ index ] ) : ( left ? other_genes[ index ] : @genes[ index ] ) }
	end

	def to_json( json : JSON::Builder ) : Void
		json.object{
			json.field( :genes ){ json.array{ @genes.each{ |gene| json.number gene } } }
			super
		}
	end
end

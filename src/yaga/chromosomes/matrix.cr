# T - internal genes class
# U - inputs class
# V - activation class

require "simple_matrix"

module YAGA

	module Chromosomes

		class Matrix( T, U, V )
			include Chromosome( SimpleMatrix( T ), U, V )

			private macro prepare_result
				{% if V == T %}
					@results.buffer.first.first
				{% elsif V == Array( T ) %}
					@results.buffer.first
				{% elsif V == Array( Array( T ) ) %}
					@results.buffer
				{% elsif V == SimpleMatrix( T ) %}
					@results
					# Ignore `else` - this is an error case
				{% end %}
			end

			RANDOM_RANGE = -5_i8 .. 5_i8

			@random_range : Range( T, T )
			@results : SimpleMatrix( T )

			def initialize( @num_inputs, @layer_index, @chromosome_index, @random_range = T.new( RANDOM_RANGE.begin ) .. T.new( RANDOM_RANGE.end ) )
				@genes = SimpleMatrix( T ).new @num_inputs, 1
				@results = SimpleMatrix( T ).new 1, 1
				randomize
			end

			def activate( inputs : U ) : V
				raise ArgumentError.new "Unsupported type: #{ U.inspect }"
			end

			def activate( inputs : Array( SimpleMatrix( T ) ) ) : V
				inputs[ @chromosome_index ].dot @genes, @results
				prepare_result
			end

			def activate( inputs : Array( Array( T ) ) ) : V
				matrix_inputs = SimpleMatrix( T ).new( inputs.size, inputs.first.size ){ |y, x| inputs[ y ][ x ] }
				matrix_inputs.dot @genes, @results
				prepare_result
			end

			def activate( inputs : Array( T ) ) : V
				matrix_inputs = SimpleMatrix( T ).new( 1, inputs.size ){ |y, x| inputs[ x ] }
				matrix_inputs.dot @genes, @results
				prepare_result
			end

			def activate( inputs : T ) : V
				@genes.mul inputs, @results
				prepare_result
			end

			def randomize : Void
				@genes.apply( @genes ){ rand @random_range }
			end

			def mutate : Void
				@genes.buffer[ rand @genes.height ][ rand @genes.width ] = rand @random_range
			end

			def replace( other : Chromosome ) : Void
				other_buffer = other.genes.as( SimpleMatrix( T ) ).buffer
				@genes.apply( @genes ){ |value, y, x| other_buffer[ y ][ x ] }
			end

			def crossover( other : Chromosome ) : Void
				other_buffer = other.genes.as( SimpleMatrix( T ) ).buffer
				target_buffer = @genes.buffer

				rand( @genes.height * @genes.width * 0.5 ).to_i.times{
					y, x = rand( @genes.height ), rand( @genes.width )
					target_buffer[ y ][ x ] = other_buffer[ y ][ x ]
				}
			end

			def size : UInt64
				@genes.width.to_u64 * @genes.height.to_u64
			end
		end

	end

end

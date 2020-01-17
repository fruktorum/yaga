# T - internal genes class
# U - inputs class
# V - activation class

require "simple_matrix"

module YAGA

	module Chromosomes

		class Matrix( T, U, V )
			include Chromosome( SimpleMatrix( T ), U, V )

			RANDOM_RANGE = -3 .. 3

			@results : SimpleMatrix( T )

			def initialize( num_inputs : Int32 )
				@genes = SimpleMatrix( T ).new num_inputs, 1
				@results = SimpleMatrix( T ).new 1, 1
				randomize
			end

			def activate( inputs : U ) : V
				{% if U == SimpleMatrix( T ) %}
					inputs.dot @genes, @results
				{% elsif U == Array( Array( T ) ) %}
					matrix_inputs = SimpleMatrix( T ).new( inputs.size, inputs.first.size ){ |y, x| inputs[ y ][ x ] }
					matrix_inputs.dot @genes, @results
				{% elsif U == Array( T ) %}
					matrix_inputs = SimpleMatrix( T ).new( 1, inputs.size ){ |y, x| inputs[ x ] }
					matrix_inputs.dot @genes, @results
				{% elsif U == T %}
					@genes.mul inputs, @results
				{% end %}

				{% if V == T %}
					@results.buffer.first.first
				{% elsif V == Array( T ) %}
					@results.buffer.first
				{% elsif V == Array( Array( T ) ) %}
					@results.buffer
				{% elsif V == SimpleMatrix( T ) %}
					@results
					# Ignore `else` - this is error
				{% end %}
			end

			def randomize : Void
				@genes.apply( @genes ){ T.new rand( RANDOM_RANGE ) }
			end

			def mutate : Void
				@genes.buffer[ rand @genes.height ][ rand @genes.width ] = T.new rand( RANDOM_RANGE )
			end

			def replace( other : Chromosome ) : Void
				other_buffer = other.genes.as( SimpleMatrix( T ) ).buffer
				@genes.apply( @genes ){ |value, y, x| other_buffer[ y ][ x ] }
			end

			def size : UInt64
				@genes.width.to_u64 * @genes.height.to_u64
			end
		end

	end

end

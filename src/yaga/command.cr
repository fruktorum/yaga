# T - internal weights class
# U - inputs class
# V - activation class

module YAGA

	abstract class Command( T, U, V )
		getter weights

		@weights : T

		abstract def activate( inputs : U ) : V
		abstract def randomize : Void
		abstract def mutate : Void

		def initialize( num_inputs : Int32 )
			@weights = T.new 0
		end

		def size : UInt64
			@weights.size.to_u64
		end

		def replace( other : Command ) : Void
			@weights.each_index{ |index| @weights[ index ] = other.weights[ index ] }
		end

		def same?( other : Command ) : Bool
			@weights == other.weights
		end
	end

end

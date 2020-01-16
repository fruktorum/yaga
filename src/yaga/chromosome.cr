# T - internal genes class
# U - inputs class
# V - activation class

module YAGA

	module Chromosome( T, U, V )
		getter genes

		@genes : T

		abstract def activate( inputs : U ) : V
		abstract def randomize : Void
		abstract def mutate : Void
		abstract def replace( other : Chromosome( T, U, V ) ) : Void

		def initialize( num_inputs : Int32 )
			@genes = T.new 0
		end

		def size : UInt64
			@genes.size.to_u64
		end

		def same?( other : Chromosome ) : Bool
			@genes == other.genes
		end
	end

end

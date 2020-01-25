# T - internal genes class
# U - inputs class
# V - activation class

module YAGA

	module Chromosome( T, U, V )
		getter genes, num_inputs, layer_index, chromosome_index

		@genes : T
		@num_inputs : UInt32
		@layer_index : UInt32
		@chromosome_index : UInt32

		abstract def activate( inputs : U ) : V
		abstract def randomize : Void
		abstract def mutate : Void
		abstract def replace( other : Chromosome( T, U, V ) ) : Void
		abstract def crossover( other : Chromosome( T, U, V ) ) : Void

		def initialize( @num_inputs, @layer_index, @chromosome_index )
		end

		def size : UInt64
			@genes.size.to_u64
		end

		def same?( other : Chromosome ) : Bool
			@genes == other.genes
		end
	end

end

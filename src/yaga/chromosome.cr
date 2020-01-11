# T - internal genes class
# U - inputs class
# V - activation class

module YAGA

	abstract class Chromosome( T, U, V )
		getter genes

		@genes : T

		abstract def activate( inputs : U ) : V
		abstract def randomize : Void
		abstract def mutate : Void

		def initialize( num_inputs : Int32 )
			@genes = T.new 0
		end

		def size : UInt64
			@genes.size.to_u64
		end

		def replace( other : Chromosome ) : Void
			@genes.each_index{ |index| @genes[ index ] = other.genes[ index ] }
		end

		def same?( other : Chromosome ) : Bool
			@genes == other.genes
		end
	end

end

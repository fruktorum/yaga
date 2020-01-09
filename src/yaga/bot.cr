require "./genome"

module YAGA

	class Bot( T )
		property fitness, generation
		getter genome

		delegate mutate, activate, to: @genome

		@genome : T
		@generation : UInt64
		@fitness : Float64 = 0

		def initialize( @generation = 0_u64 )
			@genome = T.new
		end

		def replace( other : Bot( T ) ) : Void
			@generation = other.generation
			@fitness = other.fitness
			@genome.replace other.genome
		end

		def crossover( other : Bot( T ) ) : Void
			@genome.crossover other.genome
		end

		def brain_size : UInt64
			@genome.size
		end

		def same?( other : Bot( T ) ) : Bool
			@genome.same? other.genome
		end

		def ==( other : Bot( T ) ) : Bool
			object_id == other.object_id
		end
	end

end

require "./genome"

module YAGA

	class Bot( T, V )
		property fitness, generation
		getter genome

		delegate update_random, mutate, activate, to_json, to: @genome

		@genome : T
		@generation : UInt64
		@fitness : V

		def initialize( pull : JSON::PullParser )
			@generation = 0_u64
			@genome = T.new pull
			@fitness = V.new 0
		end

		def initialize( @generation = 0_u64 )
			@genome = T.new
			@fitness = V.new 0
		end

		def replace( other : Bot( T, V ) ) : Void
			@generation = other.generation
			@fitness = other.fitness
			@genome.replace other.genome
		end

		def crossover( other : Bot( T, V ) ) : Void
			@genome.crossover other.genome
		end

		def brain_size : UInt64
			@genome.size
		end

		def same?( other : Bot( T, V ) ) : Bool
			@genome.same? other.genome
		end

		def ==( other : Bot( T, V ) ) : Bool
			object_id == other.object_id
		end
	end

end

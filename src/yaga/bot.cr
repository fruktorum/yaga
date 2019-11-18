require "./genome"

module YAGA

	class Bot( T, U )
		property fitness, generation
		getter genome

		delegate mutate, to: genome

		@genome : Genome( T )
		@generation : UInt64
		@layers : Array( U )
		@fitness : Float64 = 0

		def initialize( architecture : Array( UInt16 ), @generation = 0_u64 )
			@genome = Genome( T ).new architecture
			@layers = Array( U ).new @genome.genes.size + 1

			architecture.each{ |value| @layers << U.new( value.to_i ) }
		end

		def activate( inputs : U ) : U
			inputs.each_with_index{ |value, input_index| @layers.first[ input_index ] = value }

			@genome.genes.each_with_index{|gene, index|
				input = @layers[ index ]
				layer = @layers[ index + 1 ]

				gene.each_with_index{ |command, command_index| layer[ command_index ] = command.activate input }
			}

			@layers.last
		end

		def replace( other : Bot( T, U ) ) : Void
			@generation = other.generation
			@fitness = other.fitness
			@genome.replace other.genome
		end

		def crossover( other : Bot( T, U ) ) : Void
			@genome.crossover other.genome
		end

		def brain_size : UInt64
			@genome.size
		end

		def same?( other : Bot( T, U ) ) : Bool
			@genome.same? other.genome
		end

		def ==( other : Bot( T ) ) : Bool
			object_id == other.object_id
		end
	end

end

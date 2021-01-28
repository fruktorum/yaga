# T - internal genes class
# U - inputs class
# V - activation class

module YAGA

	module Chromosome( T, U, V )
		getter genes, num_inputs, layer_index, chromosome_index

		@random : Random = Random::DEFAULT

		@genes : T
		@num_inputs : UInt32
		@layer_index : UInt32
		@chromosome_index : UInt32

		abstract def activate( inputs : U ) : V
		abstract def randomize : Void
		abstract def mutate : Void
		abstract def replace( other : Chromosome( T, U, V ) ) : Void
		abstract def crossover( other : Chromosome( T, U, V ) ) : Void

		def initialize( pull : JSON::PullParser )
			@num_inputs = 0
			@layer_index = 0
			@chromosome_index = 0
			super
		end

		def initialize( @num_inputs, @layer_index, @chromosome_index )
		end

		def update_random( @random ) : Void
			randomize
		end

		def size : UInt64
			@genes.size.to_u64
		end

		def same?( other : Chromosome ) : Bool
			@genes == other.genes
		end

		def to_json( json : JSON::Builder ) : Void
			json.field( :num_inputs ){ json.number @num_inputs }
			json.field( :layer_index ){ json.number @layer_index }
			json.field( :chromosome_index ){ json.number @chromosome_index }
		end
	end

end

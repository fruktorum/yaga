require "spec"
require "../src/yaga"

class TestGenome
	include YAGA::Chromosome( Array( UInt8 ), Array( UInt8 ), UInt8 )

	def initialize( pull : JSON::PullParser )
		@genes = T.new( 16 ){ rand 0_u8 .. 255_u8 }
		@num_inputs = 0
		@layer_index = 0
		@chromosome_index = 0

		super
	end

	def initialize( @num_inputs, @layer_index, @chromosome_index )
		@genes = T.new( 16 ){ rand 0_u8 .. 255_u8 }
		super
	end

	def activate( inputs : U ) : V
		1_u8
	end

	def randomize : Void
		@genes.map!{ rand 0_u8 .. 255_u8 }
	end

	def mutate : Void
		@genes[ rand @genes.size ] = rand 0_u8 .. 255_u8
	end

	def replace( other : YAGA::Chromosome( T, U, V ) ) : Void
		@genes.map_with_index!{ |_, index| other.genes[ index ] }
	end

	def crossover( other : YAGA::Chromosome( T, U, V ) ) : Void
		8.times{ |index| @genes[ index ] = other.genes[ index ] }
	end
end

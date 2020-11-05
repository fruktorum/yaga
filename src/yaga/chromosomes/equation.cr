# Equations solver built within the simple Syntax Tree

# Weights: Array( UInt8 )
# Inputs: Array( Float64 )
# Outputs: Float64

# №      0        1          2      3    4    5    6    7    8       9       10       11         12          13      14   15
# Label  neg     sum        mul     1    2    x    pi   e   sin     cos     tan      lg2        lg10        lge       y    z
# Arity  1        2          2      0    0    0    0    0    1       1       1        1          1           1        0    0
# Value -{a}  {a1}+{a2}  {a1}*{a2}  1    2    X    PI   e  sin{a}  cos{a}  tan{a}  log(2){a}  log(10){a}  log(e){a}   Y    Z

# Values declaration:
# {a} - arguments
# 1 - const 1
# 2 - const 2
# PI - PI value (3.14...)
# E - E value (2.71...)

# Combination: `[ 5, 2, 2, 1, 3, 5 ]` is equal to:
# `x`, Because 4 has no arity

# Combination:
# `[ 2, 2, 5, 1, 4, 5 ]` is equal to:
# `  *  *  x  +  2  x` where arity is:
# `  2  2  0  2  0  0`

#            *
#           / \
#          *   x
#         / \
#        +   2
#       / \
#      x   nil

# Because tree is over, `+` has no pair.
# Doesn't matter - algorithm should be working even with inconsistent data.

# Final function is: ( x + ... ) * 2 * x = 2x^2
# `...` is not equal to zero: if there were multiplication instead of sum,
# result with zero would be wrong.

require "./equation_parser/tree"

module YAGA

	module Chromosomes

		class Equation
			include Chromosome( Array( UInt8 ), Array( Float64 ), Float64 )

			GENOME_SIZE = 64_u8
			COMMAND_RANGE = Array( UInt8 ).new( 14 ){ |index| index.to_u8 }

			@tree : EquationParser::Tree
			@command_range : Array( UInt8 )

			def initialize( pull : JSON::PullParser )
				@genes = Array( UInt8 ).new
				@tree = EquationParser::Tree.new @genes
				@command_range = Array( UInt8 ).new

				@num_inputs = 0
				@layer_index = 0
				@chromosome_index = 0

				pull.read_object{|key|
					case key
						when "genes" then pull.read_array{ @genes << pull.read_int.to_u8 }
						when "command_range" then pull.read_array{ @command_range << pull.read_int.to_u8 }
						when "num_inputs" then @num_inputs = pull.read_int.to_u32
						when "layer_index" then @layer_index = pull.read_int.to_u32
						when "chromosome_index" then @chromosome_index = pull.read_int.to_u32
						else pull.skip
					end
				}

				@tree.parse @genes
			end

			def initialize( @num_inputs, @layer_index, @chromosome_index, genome_size = GENOME_SIZE, @command_range = COMMAND_RANGE )
				@genes = Array( UInt8 ).new( genome_size ){ @command_range.sample @random }
				@tree = EquationParser::Tree.new @genes
			end

			def activate( inputs : Array( Float64 ) ) : Float64
				@tree.eval inputs[ @chromosome_index ].to_f64
			end

			def randomize : Void
				@genes.each_index{ |index| @genes[ index ] = @command_range.sample @random }
				@tree.parse @genes
			end

			def mutate : Void
				@genes[ @random.rand @genes.size ] = @command_range.sample @random
				@tree.parse @genes
			end

			def replace( other : YAGA::Chromosome ) : Void
				other_genes = other.genes.as T
				@genes.each_index{ |index| @genes[ index ] = other_genes[ index ] }
				@tree.parse @genes
			end

			def crossover( other : Chromosome ) : Void
				replace other
			end

			def to_json( json : JSON::Builder ) : Void
				json.object{
					json.field( :genes ){ json.array{ @genes.each{ |gene| json.number gene } } }
					json.field( :command_range ){ json.array{ @command_range.each{ |value| json.number value } } }
					super
				}
			end
		end

	end

end

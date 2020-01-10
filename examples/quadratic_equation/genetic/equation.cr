# Equations solver built within the simple Syntax Tree

# Weights: Array( UInt8 )
# Inputs: Array( Float64 )
# Outputs: Float64

# №      0        1          2      3    4    5    6    7    8       9       10       11         12          13
# Label  neg     sum        mul     1    2    x    pi   e   sin     cos     tan      lg2        lg10        lge
# Arity  1        2          2      0    0    0    0    0    1       1       1        1          1           1
# Value -{a}  {a1}+{a2}  {a1}*{a2}  1    2    X    PI   e  sin{a}  cos{a}  tan{a}  log(2){a}  log(10){a}  log(e){a}

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

require "./syntax_parser/tree"

class Equation < YAGA::Command( Array( UInt8 ), Array( Float64 ), Float64 )
	GENOME_SIZE = 64_u8
	COMMAND_RANGE = Array( UInt8 ).new( 14 ){ |index| index.to_u8 }

	@tree : SyntaxParser::Tree
	@genome_size : UInt8
	@command_range : Array( UInt8 )

	def initialize( num_inputs : Int32, @genome_size = GENOME_SIZE, @command_range = COMMAND_RANGE )
		@weights = Array( UInt8 ).new( @genome_size ){ @command_range.sample }
		@tree = SyntaxParser::Tree.new @weights
	end

	def activate( inputs : Array( Float64 ) ) : Float64
		@tree.eval inputs[ 0 ].to_i32
	end

	def randomize : Void
		@weights.each_index{ |index| @weights[ index ] = @command_range.sample }
		@tree.parse @weights
	end

	def mutate : Void
		@weights[ rand @genome_size ] = @command_range.sample
		@tree.parse @weights
	end

	def replace( other : YAGA::Command ) : Void
		@weights.each_index{ |index| @weights[ index ] = other.weights[ index ] }
		@tree.parse @weights
	end
end

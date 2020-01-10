# Binary neuron operation.

# Weights: BitArray
# Inputs: BitArray
# Outputs: Bool

# This operation has weights in amount of the inputs.
# Each weight (bit W) is connected to each input value (bit I).

# Neuron has configurable inner "operation" that provide one of several binary calculations:
# Mul: binary "AND" between result and I
# Sum: output = result + I
# Xor: output = result ^ I
# InvMul: output = result * not(I)
# InvSum: output = result + not(I)

# Output calculates between applying inner "operation" from above
# to the all inputs only activated by weights
# If no W is active (dead neuron), output is `false`.

# Example 1

# (Below shown the values "0" and "1" but please be sure that is actually "false" if "0" and "true" if "1")
# "+" is "OR"
# "*" is "AND"
# "^" is "XOR"
# "!" is "NOT"
# "NOT" applies right to the next value:
# A ^ !B ^ C is equal to (A XOR NOT(B)) XOR C

# Inputs:  1, 0, 1, 1
# Weights: 0, 0, 1, 1
# Inner operation: Mul
# Result:
# First:  weight is 0 - skip (weight is 0, does not appear in the calculations)
# Second: weight is 0 - skip (weight is 0, it also does not appear in the calculations)
# Third:  weight is 1 - Yay! Weight is 1, use it (result is 1)
# Fourth: weight is 1 - Yay! But we already have a value, so apply: Mul(Third, Fourth) = Mul(1, 1) = 1
# Output is 1

# Example 2

# Inputs:  0, 0, 0, 1
# Weights: 1, 0, 0, 1
# Inner operation: Sum
# Result:
# First:  weight is 1 - Yay use it (result is 0)
# Second: weight is 0 - skip (weight is 0, it does not appear in the calculations)
# Third:  weight is 0 - skip (weight is 0, it also does not appear in the calculations)
# Fourth: weight is 1 - Yay! But we already have a value, so apply: Sum(First, Fourth) = Sum(0, 1) = 1
# Output is 1

require "bit_array"

class Neuron < YAGA::Command( BitArray, BitArray, Bool )
	enum Operation : UInt8
		Mul
		Sum
		Xor
		InvMul
		InvSum
	end

	property operation

	@operation : Operation

	def initialize( num_inputs : Int32 )
		@weights = BitArray.new num_inputs
		@operation = Operation.new rand( Operation.names.size.to_u8 )
	end

	def activate( inputs : BitArray ) : Bool
		result = false

		@weights.each_with_index{|weight, index|
			if weight
				case @operation
					when .mul?
						return false unless inputs[ index ]
						result = true
					when .inv_mul?
						return false if inputs[ index ]
						result = true
					when .sum? then return true if inputs[ index ]
					when .inv_sum? then return true unless inputs[ index ]
					when .xor? then result ^= inputs[ index ]
				end
			end
		}

		result
	end

	def randomize : Void
		@operation = Operation.new rand( Operation.names.size.to_u8 )
		@weights.each_index{ |index| @weights[ index ] = rand( 2 ) == 1 }
	end

	def mutate : Void
		if rand( 2 ) == 0
			@operation = Operation.new rand( Operation.names.size.to_u8 )
		else
			@weights.toggle rand( @weights.size )
		end
	end

	def replace( other : YAGA::Command ) : Void
		@operation = other.operation
		super
	end

	def size : UInt64
		# Bit length + `@operation`, another configurable parameter
		@weights.size.to_u64 + 1_u64
	end

	def same?( other : YAGA::Command ) : Bool
		super && @operation == other.operation
	end
end

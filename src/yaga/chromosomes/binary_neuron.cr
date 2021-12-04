# Binary neuron operation

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

module YAGA
  module Chromosomes
    class BinaryNeuron
      include Chromosome(BitArray, BitArray, Bool)

      enum Operation : UInt8
        Mul
        Sum
        Xor
        InvMul
        InvSum
      end

      property operation

      @operation : Operation

      def initialize(pull : JSON::PullParser)
        @genes = BitArray.new 0
        @operation = Operation::Mul
        @num_inputs = 0
        @layer_index = 0
        @chromosome_index = 0

        buffer = Array(Bool).new

        pull.read_object { |key|
          case key
          when "genes"            then pull.read_array { buffer << pull.read_bool }
          when "operation"        then @operation = Operation.new pull.read_int.to_u8
          when "num_inputs"       then @num_inputs = pull.read_int.to_u32
          when "layer_index"      then @layer_index = pull.read_int.to_u32
          when "chromosome_index" then @chromosome_index = pull.read_int.to_u32
          else                         pull.skip
          end
        }

        @genes = BitArray.new @num_inputs.to_i
        buffer.each_with_index { |value, index| @genes[index] = value }
      end

      def initialize(@num_inputs, @layer_index, @chromosome_index)
        @genes = BitArray.new @num_inputs.to_i
        @operation = Operation.new @random.rand(Operation.names.size.to_u8)
      end

      def activate(inputs : BitArray) : Bool
        result = false

        @genes.each_with_index { |weight, index|
          if weight
            case @operation
            when .mul?
              return false unless inputs[index]
              result = true
            when .inv_mul?
              return false if inputs[index]
              result = true
            when .sum?     then return true if inputs[index]
            when .inv_sum? then return true unless inputs[index]
            when .xor?     then result ^= inputs[index]
            end
          end
        }

        result
      end

      def randomize : Void
        @operation = Operation.new @random.rand(Operation.names.size.to_u8)
        @genes.each_index { |index| @genes[index] = @random.rand(2) == 1 }
      end

      def mutate : Void
        if @random.rand(2) == 0
          @operation = Operation.new @random.rand(Operation.names.size.to_u8)
        else
          @genes.toggle @random.rand(@genes.size)
        end
      end

      def replace(other : Chromosome) : Void
        other_neuron = other.as self
        @genes.each_index { |index| @genes[index] = other_neuron.genes[index] }
        @operation = other_neuron.operation
      end

      def crossover(other : Chromosome) : Void
        other_genes = other.genes.as T

        slice = @random.rand @genes.size
        left = @random.rand(2_u8) == 0

        @genes.each_index { |index| @genes[index] = index <= slice ? (left ? @genes[index] : other_genes[index]) : (left ? other_genes[index] : @genes[index]) }
      end

      def size : UInt64
        # Bit length + `@operation`, another configurable parameter
        @genes.size.to_u64 + 1_u64
      end

      def same?(other : Chromosome) : Bool
        super && @operation == other.as(self).operation
      end

      def to_json(json : JSON::Builder) : Void
        json.object {
          json.field(:genes) { json.array { @genes.each { |gene| json.bool gene } } }
          json.field(:operation) { json.number @operation.value }
          super
        }
      end
    end
  end
end

# For this example used limited equation command.
# If we know that it is not needed `sin`, `cos` and others,
# we can inherited from the `Equation` class and declare
# own function requirements.

# Number set is declared on discrete Integer field,
# so we can redefine activation function to receive integers
# and respond with integers.

require "big/big_float"

require "../shared/progress_patch"

require "../../src/yaga"
require "../../src/yaga/chromosomes/equation"

require "./data"

class QuadraticEquation < YAGA::Chromosomes::Equation
	def initialize( @num_inputs, @layer_index, @chromosome_index )
		super @num_inputs, @layer_index, @chromosome_index, 15_u8, Array( UInt8 ){ 0, 1, 2, 3, 4, 5 }
	end

	def activate( inputs : Array( UInt16 ) ) : Int64
		@tree.eval( inputs[ 0 ].to_f64 ).to_i64
	end
end

YAGA::Genome.compile(
	# Generated genome class  Inputs type (array)       Inputs size
	QuadraticGenome         , Array( UInt16 )         , 1          ,

	# Activator               Activations type (array)  Outputs size
	{ QuadraticEquation     , Array( Int64 )          , 1            }
)

population = YAGA::Population( QuadraticGenome, Float64 ).new 256_u32, 12_u32, 100_u8

# Using only 3 values for the function recognition
inputs = Array( UInt16 ){ 7, 48, 112 }
outputs = Array( Int64 ){ 16, 2066, 11986 }

data = Data.new population, inputs, outputs
simulations_passed = data.train 30000, false # true for logging

puts "\n\e[0;32mFinished!\e[0m"

best_bot = population.selection.first

puts best_bot.to_json
p simulations_passed: simulations_passed, generation: best_bot.generation, max_fitness: best_bot.fitness, brain_size: best_bot.brain_size

puts

10.times{
	input = rand 128_u16
	output = Data.f input
	p input: input, prediction: best_bot.activate( [ input ] )[ 0 ], actual: output
}

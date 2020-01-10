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

require "./genetic/equation"
require "./data"

class QuadraticEquation < Equation
	def initialize( num_inputs : Int32 )
		super num_inputs, 15_u8, Array( UInt8 ){ 0, 1, 2, 3, 4, 5 }
	end

	def activate( inputs : Array( UInt16 ) ) : Int64
		@tree.eval( inputs[ 0 ].to_f64 ).to_i64
	end
end

#                     Generated genome class
YAGA::Genome.compile( QuadraticGenome,
	#                    Inputs type (almost array)        Inputs size
	                     Array( UInt16 )                 , 1          ,

	# Activator          Activations type (almost array)   Outputs size
	{ QuadraticEquation, Array( Int64 )                  , 1            }
)

population = YAGA::Population( QuadraticGenome ).new 256_u32, 12_u32

# Using only 3 values for the function recognition
inputs = Array( UInt16 ){ 7, 48, 112 }
p inputs: inputs, outputs: inputs.map{ |input| Data.f input }
gets

data = Data.new population, inputs

# Add `true` for the argument to activate the inner logging
simulations_passed = data.train 30000

puts "\n\e[0;32mFinished!\e[0m"

bot = population.selection.first

p genome: bot.genome.genes[ 0 ].map( &.weights )
p simulations_passed: simulations_passed, generation: bot.generation, max_fitness: bot.fitness, brain_size: bot.brain_size

puts

10.times{
	input = rand 128_u16
	output = Data.f input
	p input: input, prediction: bot.activate( [ input ] )[ 0 ], actual: output
}

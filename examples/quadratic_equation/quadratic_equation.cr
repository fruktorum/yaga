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
require "./train"

### PREPARE DATA

require "./dna"
population = YAGA::Population( QuadraticGenome, Float64 ).new 256, 12, 100

# Using only 3 pairs of values (points) for the function recognition
inputs = Array( UInt16 ){ 7, 48, 112 }      # x1, x2, x3
outputs = Array( Int64 ){ 16, 2066, 11986 } # y1, y2, y3
data = Data.new inputs, outputs

### TRAINING

simulations_passed = Training.train population, data, 30000, false # true for logging
puts "\n\e[0;32mFinished!\e[0m"

### ANALYTICS

best_bot = population.selection.first

p genes: best_bot.genome.dna.first.first.genes
puts best_bot.to_json
p simulations_passed: simulations_passed, generation: best_bot.generation, max_fitness: best_bot.fitness, brain_size: best_bot.brain_size

puts

### EXPLOITATION

10.times{
	input = rand 128_u16
	output = Data.f input
	p input: input, prediction: best_bot.activate( [ input ] )[ 0 ], actual: output
}

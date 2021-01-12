require "../shared/progress_patch"

require "../../src/yaga"
require "../../src/yaga/chromosomes/binary_neuron"

require "./data"
require "./train"

### PREPARE DATA

require "./dna"
population = YAGA::Population( BinaryGenome, UInt8 ).new 256, 12, 100
data = Data.new

### TRAINING

simulations_passed = Training.train_each population, 30000, data.inputs, data.outputs # Training variant 1 - Each
# simulations_passed = Training.train_world population, 30000, data.inputs, data.outputs # Training variant 2 - World
puts "\n\e[0;32mFinished!\e[0m"

### ANALYTICS

best_bot = population.selection.first

puts best_bot.to_json
p simulations_passed: simulations_passed, generation: best_bot.generation, max_fitness: best_bot.fitness, brain_size: best_bot.brain_size

puts

data.inputs.each_with_index{ |input, index| p input: input, prediction: best_bot.activate( input ), actual: data.outputs[ index ] }

puts "Press enter for exploitation"
gets

### EXPLOITATION

require "./usage"
simulate population, data, best_bot
p output: best_bot.activate( data.inputs.sample.tap{ |input| p input: input } )

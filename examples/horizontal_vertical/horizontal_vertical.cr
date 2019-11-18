require "../shared/progress_patch"

require "../../src/yaga"

require "./genetic/neuron"
require "./initialization"
require "./training_method"

population = YAGA::Population( Neuron, BitArray ).new [ 9_u16, 4_u16, 2_u16 ]
data = Data.new

simulations = data.train population, 30000
bot = population.selection.first

puts "\n\e[0;32mFinished!\e[0m"

p genome: bot.genome.genes
p generation: bot.generation, max_fitness: bot.fitness, brain_size: bot.brain_size

puts

data.inputs.each_with_index{ |input, index| p input: input, prediction: bot.activate( input ), actual: data.outputs[ index ] }

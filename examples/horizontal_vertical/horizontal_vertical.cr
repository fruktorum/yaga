require "../shared/progress_patch"

require "../../src/yaga"

require "./genetic/neuron"
require "./initialization"
require "./training_method"

#                     Generated genome class
YAGA::Genome.compile( BinaryGenome,
	#                 Inputs type (almost array)       Inputs size
	                  BitArray                       , 9          ,

	# Activator       Activations type (almost array)  Outputs size
	{ Neuron   ,      BitArray                       , 4            },
	{ Neuron   ,      BitArray                       , 2            }
)

population = YAGA::Population( BinaryGenome ).new
data = Data.new

simulations = data.train population, 30000
puts "\n\e[0;32mFinished!\e[0m"

bot = population.selection.first

p genome: bot.genome.genes
p generation: bot.generation, max_fitness: bot.fitness, brain_size: bot.brain_size

puts

data.inputs.each_with_index{ |input, index| p input: input, prediction: bot.activate( input ), actual: data.outputs[ index ] }

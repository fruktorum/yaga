require "../shared/progress_patch"

require "../../src/yaga"
require "../../src/yaga/chromosomes/binary_neuron"

require "./data"

YAGA::Genome.compile(
	# Generated genome class           Inputs type (almost array)       Inputs size
	BinaryGenome                     , BitArray                       , 9          ,

	# Activator                        Activations type (almost array)  Outputs size
	{ YAGA::Chromosomes::BinaryNeuron, BitArray                       , 4            },
	{ YAGA::Chromosomes::BinaryNeuron, BitArray                       , 2            }
)

population = YAGA::Population( BinaryGenome ).new 256_u32, 12_u32
data = Data.new

simulations_passed = data.train population, 30000
puts "\n\e[0;32mFinished!\e[0m"

bot = population.selection.first

p genome: bot.genome.chromosome_layers
p simulations_passed: simulations_passed, generation: bot.generation, max_fitness: bot.fitness, brain_size: bot.brain_size

puts

data.inputs.each_with_index{ |input, index| p input: input, prediction: bot.activate( input ), actual: data.outputs[ index ] }

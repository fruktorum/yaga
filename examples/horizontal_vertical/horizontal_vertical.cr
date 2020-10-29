require "../shared/progress_patch"

require "../../src/yaga"
require "../../src/yaga/chromosomes/binary_neuron"

require "./data"

### PREPARE DATA

YAGA::Genome.compile(
	# Generated genome class           Inputs type (array)       Inputs size
	BinaryGenome                     , BitArray                , 9          ,

	# Activator                        Activations type (array)  Outputs size
	{ YAGA::Chromosomes::BinaryNeuron, BitArray                , 4            },
	{ YAGA::Chromosomes::BinaryNeuron, BitArray                , 2            }
)

population = YAGA::Population( BinaryGenome, UInt8 ).new 256_u32, 12_u32, 100_u8
data = Data.new

### TRAINING

simulations_passed = data.train_each population, 30000 # Training variant 1
# simulations_passed = data.train_world population, 30000 # Training variant 2
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

population.simulate_each{|bot|
	result = Array( BitArray ).new( 16 ){ BitArray.new 2 }

	data.inputs.each_with_index{|input, input_index|
		bot.activate( input ).each_with_index{|value, index|
			result[ input_index ][ index ] = value
		}
	}

	print "\e[0;32m" if bot.same? best_bot
	p result: result.map( &.to_a.map{ |value| value ? 1_u8 : 0_u8 } )
	print "\e[0m" if bot.same? best_bot
}

p output: best_bot.activate( data.inputs.sample.tap{ |input| p input: input } )

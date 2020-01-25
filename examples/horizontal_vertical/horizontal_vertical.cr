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

population = YAGA::Population( BinaryGenome ).new 256_u32, 12_u32
data = Data.new

### TRAINING

simulations_passed = data.train population, 30000
puts "\n\e[0;32mFinished!\e[0m"

### ANALYTICS

bot = population.selection.first

p genome: bot.genome.dna
p simulations_passed: simulations_passed, generation: bot.generation, max_fitness: bot.fitness, brain_size: bot.brain_size

puts

data.inputs.each_with_index{ |input, index| p input: input, prediction: bot.activate( input ), actual: data.outputs[ index ] }

puts "Press enter for exploitation"
gets

### EXPLOITATION

population.simulate_each{|population_bot|
	result = Array( BitArray ).new( 16 ){ BitArray.new 2 }

	data.inputs.each_with_index{|input, input_index|
		population_bot.activate( input ).each_with_index{|value, index|
			result[ input_index ][ index ] = value
		}
	}

	print "\e[0;32m" if population_bot.same? bot
	p result: result.map( &.to_a.map{ |value| value ? 1_u8 : 0_u8 } )
	print "\e[0m" if population_bot.same? bot
}

p output: bot.activate( data.inputs.sample.tap{ |input| p input: input } )

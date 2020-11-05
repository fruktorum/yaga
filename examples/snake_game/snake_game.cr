require "../../src/yaga"

require "./genetic/dna"
require "./game_engine/field"

macro selection_fitness( bots, selection_size )
	{{ bots }}.map( &.fitness ).sort.reverse.first {{ selection_size }}
end

def run_simulation( field : Game::Field ) : Void
	while field.snakes.size > 0
		field.tick
	end
end

def train( fields : StaticArray, population : YAGA::Population ) : Void
	target_fitness = 5000_u32
	target_generation = 3000_u64

	population.before_simulation{
		population.bots.each_with_index{ |snake, index| fields[ index % fields.size ].snakes << snake.as( Game::Snake ) }
		fields.each &.reset
	}

	population.after_simulation{ |generation| p generation: "#{ generation }/#{ target_generation }", steps: population.bots.max_by( &.fitness ).as( Game::Snake ).steps_alive, target: target_fitness, fitness: selection_fitness( population.bots, population.selection.size ) }

	population.train_world( target_fitness, target_generation ){ |bots| fields.each{ |field| run_simulation field } }

	best = population.bots.max_by( &.fitness ).as Game::Snake
	puts "\n", best.to_json
	p steps: best.steps_alive, fitness: best.fitness, brain_size: best.brain_size
	gets

	population.bots.each &.replace( best )
end

playground_params = { 136_u16, 35_u16, 35_u16 } # Field width, Field height, Food amount on field
playground_bots_count = 32

population_size = 256_u32
selection_size = 12_u32

random = Random.new 3333

fields = StaticArray( Game::Field, 8 ).new{ Game::Field.new( *playground_params, random ).tap &.hide }

population = YAGA::Population( SnakeGenetic::DNA, UInt32 ).new( population_size, selection_size, 75_u8, random ){|index|
	field_index = index % playground_bots_count

	x = ( field_index * 16 - (field_index / 8).to_u32 * 128 + 11 ).to_u16 # 11, 27, 43, 59, 75, 91, 107, 123, 11, 27, 43, 59, 75, 91, 107, 123, 11, 27, 43, 59, 75, 91, 107, 123, 11, 27, 43, 59, 75, 91, 107, 123
	y = ( (field_index / 8).to_u8 * 7 + 7 ).to_u16                        #  7,  7,  7,  7,  7,  7,   7,   7, 14, 14, 14, 14, 14, 14,  14,  14, 21, 21, 21, 21, 21, 21,  21,  21, 28, 28, 28, 28, 28, 28,  28,  28

	Game::Snake.new x, y
}

puts "Please enter the saved Genome, or press enter to start the training: "
json_genome = gets.to_s

if json_genome.empty?
	train fields, population
else
	loaded_snake = YAGA::Bot( SnakeGenetic::DNA, UInt32 ).from_json json_genome
	population.bots.each &.replace( loaded_snake )
end

simulation_field = fields.first.tap{ |field| field.show; field.random = Random.new }
simulation_bots = population.bots.first playground_bots_count

population.before_simulation{
	simulation_bots.each_with_index{ |snake, index| simulation_field.snakes << snake.as( Game::Snake ) }

	simulation_field.reset
	simulation_field.render

	p :prepared
	sleep 0.75
}

population.after_simulation{|generation|
	best = simulation_bots.max_by( &.fitness ).as Game::Snake
	p generation: best.generation, leader_steps: best.steps_alive, fitness: selection_fitness( simulation_bots, selection_size )
	sleep 3
}

loop{ population.simulate_world{ |bots| run_simulation simulation_field } }

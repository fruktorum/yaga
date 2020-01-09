require "./bot"

module YAGA

	class Population( T )
		TOTAL_BOTS = 64_u16
		TOP_BOTS = 8_u16

		SIMULATIONS_HISTORY = 200_u64

		MUTATION_BOTS = TOP_BOTS * 4 .. TOTAL_BOTS - 3
		CROSSOVER_BOTS = TOP_BOTS * 3 .. TOTAL_BOTS - 2

		EXTRA_EVOLUTION_BOTS = TOTAL_BOTS - ( TOTAL_BOTS / TOP_BOTS ).to_u16 - 2 .. TOTAL_BOTS - 2

		getter bots, selection, fitness_history

		@bots : Array( Bot( T ) )
		@selection : Array( Bot( T ) )
		@fitness_history : Array( Float64 )
		@generation : UInt64 = 0

		def initialize
			@bots = Array( Bot( T ) ).new( TOTAL_BOTS ){ Bot( T ).new }
			@selection = Array( Bot( T ) ).new( TOP_BOTS ){ Bot( T ).new }
			@fitness_history = Array( Float64 ).new SIMULATIONS_HISTORY
		end

		def train( goal : Float64, simulations_cap : UInt64 = 10000_u64, &block : Proc( Bot( T ), Float64 ) ) : UInt64
			@fitness_history.clear
			training_simulation &block

			while @selection.first.fitness < goal && @generation < simulations_cap
				evolve
				training_simulation &block
			end

			@generation
		end

		private def training_simulation( &block : Proc( Bot( T ), Float64 ) ) : Void
			max_fitness = Float64::MIN

			@bots.each{|bot|
				fitness = yield bot
				bot.fitness = fitness
				max_fitness = fitness if max_fitness <= fitness
			}

			prepare_selection

			@fitness_history.shift if @fitness_history.size == SIMULATIONS_HISTORY
			@fitness_history << max_fitness
		end

		private def evolve : Void
			if @generation <= 1 && @bots.all?{ |bot| bot.fitness <= 0 }
				@generation = 0
				@bots.each{|bot|
					bot.generation = @generation
					bot.fitness = 0_f64
					bot.genome.generate
				}
			else
				@generation += 1
				prepare_population
				process_evolution
				prevent_stagnation if @generation >= SIMULATIONS_HISTORY && bad_statistics?
			end
		end

		private def prepare_selection : Void
			current_selection = 0
			@bots.sort_by{ |bot| -bot.fitness }.each{|bot|
				if current_selection == 0 || !@selection[ 0 .. current_selection ].any?( &.same? bot )
					@selection[ current_selection ].replace bot
					current_selection += 1
					break if current_selection == TOP_BOTS
				end
			}

			( current_selection .. TOP_BOTS - 1 ).each{ |index| @selection[ index ].replace @bots.sample }
		end

		private def prepare_population : Void
			selection_index = 0 # Avoid mod operation: selection_index = bot_index % TOP_BOTS
			@bots.each{|bot|
				bot.replace @selection[ selection_index ]
				bot.fitness = 0_f64

				selection_index += 1
				selection_index -= TOP_BOTS if selection_index >= TOP_BOTS
			}
		end

		private def process_evolution : Void
			@bots[ MUTATION_BOTS ].each{|bot|
				bot.mutate
				bot.generation = @generation
			}

			selection_index = 0 # Avoid mod operation: selection_index = bot_index % TOP_BOTS
			@bots[ CROSSOVER_BOTS ].each{|bot|
				bot.crossover @selection[ selection_index ]
				bot.generation = @generation

				selection_index += 1
				selection_index -= TOP_BOTS if selection_index >= TOP_BOTS
			}

			@bots[ -2 ].tap{|bot|
				bot.generation = @generation
				bot.genome.generate
				bot.crossover @selection[ 0 ]
			}

			@bots[ -1 ].tap{|bot|
				bot.generation = @generation
				bot.genome.generate
			}
		end

		private def prevent_stagnation : Void
			@bots[ EXTRA_EVOLUTION_BOTS ].each{|bot|
				bot.generation = @generation
				bot.genome.generate
			}
		end

		private def bad_statistics? : Bool
			min = max = @fitness_history.first
			min_index = max_index = 0

			@fitness_history.each_with_index{|iteration, index|
				if min > iteration
					min = iteration
					min_index = index
				end

				if max < iteration
					max = iteration
					max_index = index
				end
			}

			max_index < SIMULATIONS_HISTORY * 0.5 && ( min_index > SIMULATIONS_HISTORY * 0.6 || min_index == max_index )
		end
	end

end

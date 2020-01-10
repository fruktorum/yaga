require "./bot"

module YAGA

	class Population( T )
		TOTAL_BOTS = 64_u32
		SELECTION_BOTS = 8_u32

		SIMULATIONS_HISTORY = 200_u64

		getter bots, selection, total_bots, fitness_history

		@total_bots : UInt32
		@selection_bots : UInt32

		@mutation_bots : Range( UInt32, UInt32 )
		@crossover_bots : Range( UInt32, UInt32 )
		@extra_evolution_bots : Range( UInt32, UInt32 )

		@bots : Array( Bot( T ) )
		@selection : Array( Bot( T ) )
		@fitness_history : Array( Float64 )
		@generation : UInt64 = 0

		def initialize( @total_bots = TOTAL_BOTS, @selection_bots = SELECTION_BOTS )
			@bots = Array( Bot( T ) ).new( @total_bots ){ Bot( T ).new }
			@selection = Array( Bot( T ) ).new( @selection_bots ){ Bot( T ).new }
			@fitness_history = Array( Float64 ).new SIMULATIONS_HISTORY

			@mutation_bots = ( @total_bots / 2 ).to_u32 .. @total_bots - 3
			@crossover_bots = ( @total_bots / 2 - @total_bots / 8 ).to_u32 - 1 .. @total_bots - 3
			@extra_evolution_bots = @total_bots - ( @total_bots / @selection_bots ).to_u32 - 2 .. @total_bots - 2
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
					break if current_selection == @selection_bots
				end
			}

			( current_selection .. @selection_bots - 1 ).each{ |index| @selection[ index ].replace @bots.sample }
		end

		private def prepare_population : Void
			selection_index = 0 # Avoid mod operation: selection_index = bot_index % @selection_bots
			@bots.each{|bot|
				bot.replace @selection[ selection_index ]
				bot.fitness = 0_f64

				selection_index += 1
				selection_index -= @selection_bots if selection_index >= @selection_bots
			}
		end

		private def process_evolution : Void
			@bots[ @mutation_bots ].each{|bot|
				bot.mutate
				bot.generation = @generation
			}

			selection_index = 0 # Avoid mod operation: selection_index = bot_index % @selection_bots
			@bots[ @crossover_bots ].each{|bot|
				bot.crossover @selection[ selection_index ]
				bot.generation = @generation

				selection_index += 1
				selection_index -= @selection_bots if selection_index >= @selection_bots
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
			@bots[ @extra_evolution_bots ].each{|bot|
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

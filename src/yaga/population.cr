require "./bot"

module YAGA

	class Population( T )
		TOTAL_BOTS = 64_u32
		SELECTION_BOTS = 8_u32

		SIMULATIONS_HISTORY = 200_u64

		property generation
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

		@before_simulation_action : Proc( UInt64, Void )?
		@after_simulation_action : Proc( UInt64, Void )?

		def initialize( @total_bots = TOTAL_BOTS, @selection_bots = SELECTION_BOTS, &block : Int32 -> Bot( T ) )
			raise ArgumentError.new( "Total bots amount should be greater than or equal to 11, got: #{ @total_bots }" ) if @total_bots < 11
			raise ArgumentError.new( "Selection bots amount should be greater than or equal to 2, got: #{ @selection_bots }" ) if @selection_bots < 2

			@bots = Array( Bot( T ) ).new( @total_bots ){ |bot_index| yield bot_index }

			@selection = Array( Bot( T ) ).new( @selection_bots ){ Bot( T ).new }
			@fitness_history = Array( Float64 ).new SIMULATIONS_HISTORY

			@mutation_bots = ( @total_bots / 2 ).to_u32 .. @total_bots - 3
			@crossover_bots = ( @total_bots / 2 - @total_bots / 8 ).to_u32 - 1 .. @total_bots - 3
			@extra_evolution_bots = @total_bots - ( @total_bots / @selection_bots ).to_u32 - 2 .. @total_bots - 2
		end

		def initialize( @total_bots = TOTAL_BOTS, @selection_bots = SELECTION_BOTS )
			raise ArgumentError.new( "Total bots amount should be greater than or equal to 11, got: #{ @total_bots }" ) if @total_bots < 11
			raise ArgumentError.new( "Selection bots amount should be greater than or equal to 2, got: #{ @selection_bots }" ) if @selection_bots < 2

			@bots = Array( Bot( T ) ).new( @total_bots ){ Bot( T ).new }

			@selection = Array( Bot( T ) ).new( @selection_bots ){ Bot( T ).new }
			@fitness_history = Array( Float64 ).new SIMULATIONS_HISTORY

			@mutation_bots = ( @total_bots / 2 ).to_u32 .. @total_bots - 3
			@crossover_bots = ( @total_bots / 2 - @total_bots / 8 ).to_u32 - 1 .. @total_bots - 3
			@extra_evolution_bots = @total_bots - ( @total_bots / @selection_bots ).to_u32 - 2 .. @total_bots - 2
		end

		def before_simulation( &block : UInt64 -> Void ) : Void
			@before_simulation_action = block
		end

		def after_simulation( &block : UInt64 -> Void ) : Void
			@after_simulation_action = block
		end

		def train_world( goal : Float64, simulations_cap : UInt64 = 10000_u64, &block : Array( Bot( T ) ) -> Void ) : UInt64
			@fitness_history.clear
			training_world_simulation &block

			while @selection.first.fitness < goal && @generation < simulations_cap
				evolve
				training_world_simulation &block
			end

			@generation
		end

		def train_each( goal : Float64, simulations_cap : UInt64 = 10000_u64, &block : Bot( T ) -> Float64 ) : UInt64
			@fitness_history.clear
			training_each_simulation &block

			while @selection.first.fitness < goal && @generation < simulations_cap
				evolve
				training_each_simulation &block
			end

			@generation
		end

		def simulate_world( &block : Array( Bot( T ) ) -> Void ) : Void
			( before_action = @before_simulation_action ) && before_action.call( @generation )
			yield @bots
			( after_action = @after_simulation_action ) && after_action.call( @generation )
		end

		def simulate_each( &block : Bot( T ) -> Void ) : Void
			( before_action = @before_simulation_action ) && before_action.call( @generation )
			@bots.each{ |bot| yield bot }
			( after_action = @after_simulation_action ) && after_action.call( @generation )
		end

		private def training_each_simulation( &block : Bot( T ) -> Float64 ) : Void
			max_fitness = Float64::MIN

			@selection[ @selection_bots - 1 ].replace @bots.max_by( &.fitness ) # Prevent stagnation if a previous leader does not hit target

			( before_action = @before_simulation_action ) && before_action.call( @generation )

			@bots.each{|bot|
				fitness = yield bot
				bot.fitness = fitness
				max_fitness = fitness if max_fitness < fitness
			}

			prepare_selection

			@fitness_history.shift if @fitness_history.size == SIMULATIONS_HISTORY
			@fitness_history << max_fitness

			( after_action = @after_simulation_action ) && after_action.call( @generation )
		end

		private def training_world_simulation( &block : Array( Bot( T ) ) -> Void ) : Void
			max_fitness = Float64::MIN

			@selection[ @selection_bots - 1 ].replace @bots.max_by( &.fitness ) # Prevent stagnation if a previous leader does not hit target

			( before_action = @before_simulation_action ) && before_action.call( @generation )

			@bots.each{ |bot| bot.fitness = 0_f64 }
			yield @bots
			@bots.each{ |bot| max_fitness = bot.fitness if max_fitness < bot.fitness }

			prepare_selection

			@fitness_history.shift if @fitness_history.size == SIMULATIONS_HISTORY
			@fitness_history << max_fitness

			( after_action = @after_simulation_action ) && after_action.call( @generation )
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
				next if @selection.first( current_selection ).any? &.same?( bot )
				@selection[ current_selection ].replace bot
				current_selection += 1
				break if current_selection == @selection_bots - 1
			}

			( current_selection + 2 .. @selection_bots - 1 ).each{ |index| @selection[ index ].replace @bots.sample }
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

			@bots[ -5 .. -3 ].each{|bot|
				bot.genome.generate
				bot.crossover @selection[ 0 ]
				bot.generation = @generation
			}

			@bots[ -2 .. -1 ].each{|bot|
				bot.genome.generate
				bot.generation = @generation
			}
		end

		private def prevent_stagnation : Void
			@bots[ @extra_evolution_bots ].each{|bot|
				bot.genome.generate
				bot.generation = @generation
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

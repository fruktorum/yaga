require "./bot"

module YAGA

	class Population( T )
		TOTAL_BOTS = 64_u32
		SELECTION_BOTS = 8_u32
		MUTATION_PERCENT = 10_u8

		SIMULATIONS_HISTORY = 200_u64

		property generation
		getter bots, selection, total_bots, selection_bots, fitness_history

		@total_bots : UInt32
		@selection_bots : UInt32
		@mutation_percent : UInt8

		@mutation_bots : UInt32
		@crossover_bots : UInt32
		@extra_evolution_bots : Range( UInt32, UInt32 )

		@bots : Array( Bot( T ) )
		@selection : Array( Bot( T ) )
		@fitness_history : Array( Float64 )
		@generation : UInt64 = 0

		@before_simulation_action : Proc( UInt64, Void )?
		@after_simulation_action : Proc( UInt64, Void )?

		@before_evolution_action : Proc( UInt64, Void )?
		@after_evolution_action : Proc( UInt64, Void )?

		def initialize( @total_bots = TOTAL_BOTS, @selection_bots = SELECTION_BOTS, @mutation_percent = MUTATION_PERCENT, &block : Int32 -> Bot( T ) )
			raise ArgumentError.new( "Total bots amount should be greater than or equal to 11, got: #{ @total_bots }" ) if @total_bots < 11
			raise ArgumentError.new( "Selection bots amount should be greater than or equal to 2, got: #{ @selection_bots }" ) if @selection_bots < 2

			@bots = Array( Bot( T ) ).new( @total_bots ){ |bot_index| yield bot_index }

			@selection = Array( Bot( T ) ).new( @selection_bots ){ Bot( T ).new }
			@fitness_history = Array( Float64 ).new SIMULATIONS_HISTORY

			@mutation_bots = @total_bots - ( @total_bots / 2 ).to_u32 - 2
			@crossover_bots = @total_bots - ( @total_bots / 2 - @total_bots / 8 ).to_u32 - 1
			@extra_evolution_bots = @total_bots - ( @total_bots / @selection_bots ).to_u32 - 2 .. @total_bots - 2
		end

		def initialize( @total_bots = TOTAL_BOTS, @selection_bots = SELECTION_BOTS, @mutation_percent = MUTATION_PERCENT )
			raise ArgumentError.new( "Total bots amount should be greater than or equal to 11, got: #{ @total_bots }" ) if @total_bots < 11
			raise ArgumentError.new( "Selection bots amount should be greater than or equal to 2, got: #{ @selection_bots }" ) if @selection_bots < 2

			@bots = Array( Bot( T ) ).new( @total_bots ){ Bot( T ).new }

			@selection = Array( Bot( T ) ).new( @selection_bots ){ Bot( T ).new }
			@fitness_history = Array( Float64 ).new SIMULATIONS_HISTORY

			@mutation_bots = @total_bots - ( @total_bots / 2 ).to_u32 - 2
			@crossover_bots = @total_bots - ( @total_bots / 2 - @total_bots / 8 ).to_u32 - 1
			@extra_evolution_bots = @total_bots - ( @total_bots / @selection_bots ).to_u32 - 2 .. @total_bots - 2
		end

		def before_simulation( &block : UInt64 -> Void ) : Void
			@before_simulation_action = block
		end

		def after_simulation( &block : UInt64 -> Void ) : Void
			@after_simulation_action = block
		end

		def before_evolution( &block : UInt64 -> Void ) : Void
			@before_evolution_action = block
		end

		def after_evolution( &block : UInt64 -> Void ) : Void
			@after_evolution_action = block
		end

		def train_world( goal : Float64, simulations_cap : UInt64 = 10000_u64, &block : Array( Bot( T ) ) -> Void ) : UInt64
			@fitness_history.clear
			training_world_simulation &block

			while @selection.first.fitness < goal && @generation < simulations_cap
				evolve!
				training_world_simulation &block
			end

			best = @bots.max_by &.fitness
			prepare_selection best

			@generation
		end

		def train_each( goal : Float64, simulations_cap : UInt64 = 10000_u64, &block : Bot( T ) -> Float64 ) : UInt64
			@fitness_history.clear
			training_each_simulation &block

			while @selection.first.fitness < goal && @generation < simulations_cap
				evolve!
				training_each_simulation &block
			end

			best = @bots.max_by &.fitness
			prepare_selection best

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

		# Usually it is not needed to call this method explicitly
		# But there are no restrictions about that
		def evolve! : Void
			( before_action = @before_evolution_action ) && before_action.call( @generation )

			if @generation <= 1 && @bots.all?{ |bot| bot.fitness <= 0 }
				@generation = 0
				@bots.each{|bot|
					bot.generation = @generation
					bot.fitness = 0_f64
					bot.genome.generate
				}
			else
				@generation += 1
				process_evolution
				prevent_stagnation if @generation >= SIMULATIONS_HISTORY && bad_statistics?
			end

			( after_action = @after_evolution_action ) && after_action.call( @generation )
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

		private def process_evolution : Void
			@bots.each_with_index{|bot, index|
				selection_index = index % @selection_bots

				while selection_index < @selection_bots && ( selection_bot = @selection[ selection_index ] ).same? bot
					selection_index += 1
				end
				next unless selection_bot

				bot.crossover selection_bot
				bot.generation = @generation
			}

			@bots.each{|bot|
				if rand( 0_u8 ... 100_u8 ) < @mutation_percent
					bot.mutate
					bot.generation = @generation
				end
			}

			# Prevent stagnation - add best previous selection
			@selection.each_with_index{ |selection_bot, index| @bots[ @selection_bots + index ].replace selection_bot }

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

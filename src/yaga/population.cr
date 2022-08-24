require "./bot"

module YAGA
  class Population(T, V)
    TOTAL_BOTS       = 64_u32
    SELECTION_BOTS   =  8_u32
    MUTATION_PERCENT =  10_u8
    PERCENT_RANGE    = 1_u8..100_u8

    SIMULATIONS_HISTORY = 400_u64

    property generation
    getter bots, selection, total_bots, selection_bots, fitness_history

    @random : Random
    @crossover_enabled : Bool

    @total_bots : UInt32
    @selection_bots : UInt32
    @mutation_percent : UInt8

    @mutation_bots : UInt32
    @crossover_bots : UInt32
    @extra_evolution_bots : Range(UInt32, UInt32)

    @bots : Array(Bot(T, V))
    @selection : Array(Bot(T, V))
    @fitness_history : Array(V)
    @generation : UInt64 = 0

    @before_simulation_action : Proc(UInt64, Bool, Void)?
    @after_simulation_action : Proc(UInt64, Bool, Void)?

    @before_evolution_action : Proc(UInt64, Void)?
    @after_evolution_action : Proc(UInt64, Void)?

    @before_training_action : Proc(UInt64, V, UInt64, Void)?
    @after_training_action : Proc(UInt64, V, UInt64, Void)?

    def initialize(@total_bots = TOTAL_BOTS, @selection_bots = SELECTION_BOTS, @mutation_percent = MUTATION_PERCENT, @crossover_enabled = true, @random = Random::DEFAULT, &block : Int32 -> Bot(T, V))
      raise ArgumentError.new("Total bots amount should be greater than or equal to 16, got: #{@total_bots}") if @total_bots < 16
      raise ArgumentError.new("Selection bots amount should be at most half of total bots, got: #{@selection_bots}") if @selection_bots * 2 > @total_bots

      @bots = Array(Bot(T, V)).new(@total_bots) { |bot_index| yield(bot_index).tap &.update_random(@random) }
      @selection = Array(Bot(T, V)).new(@selection_bots) { Bot(T, V).new.tap &.update_random(@random) }

      @fitness_history = Array(V).new SIMULATIONS_HISTORY

      @crossover_bots = @total_bots - @total_bots // 2 - @total_bots // 8 - 1
      @mutation_bots = @total_bots - @total_bots // 2 + (@crossover_enabled ? 0 : @crossover_bots) - 2
      @extra_evolution_bots = @total_bots - @total_bots // 4 - 5..@total_bots - 6
    end

    def initialize(@total_bots = TOTAL_BOTS, @selection_bots = SELECTION_BOTS, @mutation_percent = MUTATION_PERCENT, @crossover_enabled = true, @random = Random::DEFAULT)
      raise ArgumentError.new("Total bots amount should be greater than or equal to 16, got: #{@total_bots}") if @total_bots < 16
      raise ArgumentError.new("Selection bots amount should be at most half of total bots, got: #{@selection_bots}") if @selection_bots * 2 > @total_bots

      @bots = Array(Bot(T, V)).new(@total_bots) { Bot(T, V).new.tap &.update_random(@random) }
      @selection = Array(Bot(T, V)).new(@selection_bots) { Bot(T, V).new.tap &.update_random(@random) }

      @fitness_history = Array(V).new SIMULATIONS_HISTORY

      @crossover_bots = @total_bots - @total_bots // 2 - @total_bots // 8 - 1
      @mutation_bots = @total_bots - @total_bots // 2 + (@crossover_enabled ? 0 : @crossover_bots) - 2
      @extra_evolution_bots = @total_bots - @total_bots // 4 - 5..@total_bots - 6
    end

    def before_simulation(&block : UInt64, Bool -> Void) : Void
      @before_simulation_action = block
    end

    def after_simulation(&block : UInt64, Bool -> Void) : Void
      @after_simulation_action = block
    end

    def before_evolution(&block : UInt64 -> Void) : Void
      @before_evolution_action = block
    end

    def after_evolution(&block : UInt64 -> Void) : Void
      @after_evolution_action = block
    end

    def before_training(&block : UInt64, V, UInt64 -> Void) : Void
      @before_training_action = block
    end

    def after_training(&block : UInt64, V, UInt64 -> Void) : Void
      @after_training_action = block
    end

    def train_world(goal : V, generation_cap : UInt64 = 10000_u64, &block : Array(Bot(T, V)), UInt64 -> Void) : UInt64
      @fitness_history.clear

      trained_generations = generation_cap > @generation ? generation_cap - @generation : 0_u64
      @before_training_action.try &.call(@generation, goal, trained_generations)

      training_world_simulation &block

      while @bots.max_by(&.fitness).fitness < goal && @generation < generation_cap
        evolve! true
        training_world_simulation &block
      end

      best = @bots.max_by &.fitness
      prepare_selection best

      @after_training_action.try &.call(@generation, goal, trained_generations)

      @generation
    end

    def train_each(goal : V, generation_cap : UInt64 = 10000_u64, &block : Bot(T, V), UInt64 -> V) : UInt64
      @fitness_history.clear

      trained_generations = generation_cap > @generation ? generation_cap - @generation : 0_u64
      @before_training_action.try &.call(@generation, goal, trained_generations)

      training_each_simulation &block

      while @bots.max_by(&.fitness).fitness < goal && @generation < generation_cap
        evolve! true if @bots.max_by(&.fitness).fitness < goal && @generation < generation_cap
        training_each_simulation &block
      end

      best = @bots.max_by &.fitness
      prepare_selection best

      @after_training_action.try &.call(@generation, goal, trained_generations)

      @generation
    end

    def simulate_world(&block : Array(Bot(T, V)), UInt64 -> Void) : Void
      @before_simulation_action.try &.call(@generation, false)
      @bots.each { |bot| bot.fitness = V.new 0 }
      yield @bots, @generation
      @after_simulation_action.try &.call(@generation, false)
    end

    def simulate_each(&block : Bot(T, V), UInt64 -> Void) : Void
      @before_simulation_action.try &.call(@generation, false)
      @bots.each { |bot|
        bot.fitness = V.new 0
        yield bot, @generation
      }
      @after_simulation_action.try &.call(@generation, false)
    end

    # Usually it is not needed to call this method explicitly
    # But there are no restrictions about that
    # Do not use argument `native`, it is only for internal usage
    # Or selection will not be collected
    def evolve!(native : Bool = false) : Void
      if @generation <= 1 && @bots.all? { |bot| bot.fitness <= 0 }
        @generation = 0
        @bots.each { |bot|
          bot.generation = @generation
          bot.fitness = V.new 0
          bot.genome.generate
        }
      else
        if native
          best = @bots.max_by &.fitness
          prepare_selection best

          @fitness_history.shift if @fitness_history.size == SIMULATIONS_HISTORY
          @fitness_history << best.fitness
        end

        @before_evolution_action.try &.call(@generation)

        @generation += 1
        process_evolution
        prevent_stagnation if @generation >= SIMULATIONS_HISTORY && bad_statistics?

        @after_evolution_action.try &.call(@generation)
      end
    end

    # Crossover specific amount of bots with best selection
    def crossover : Void
      selection_index = 0 # Optimization: `@selection[ current_selection % @selection_bots ]` works slower
      @bots[@selection_bots, @crossover_bots].each { |bot|
        bot.crossover @selection[selection_index]
        bot.generation = @generation

        selection_index += 1
        selection_index -= @selection_bots if selection_index >= @selection_bots
      }
    end

    # Mutate specific amount of bots out of selection
    def mutate : Void
      @bots[@selection_bots, @mutation_bots].each { |bot|
        next if @random.rand(PERCENT_RANGE) >= @mutation_percent
        bot.mutate
        bot.generation = @generation
      }
    end

    # Reset lask part of bots to prevent stagnation
    def finalize_evolution : Void
      # 1. Reset and crossover 3 bots with best bot in selection
      @bots[-5..-3].each { |bot|
        bot.genome.generate
        bot.crossover @selection[0]
        bot.generation = @generation
      }

      # 2. Reset last 2 bots
      @bots[-2..-1].each { |bot|
        bot.genome.generate
        bot.generation = @generation
      }
    end

    private def training_each_simulation(&block : Bot(T, V), UInt64 -> V) : Void
      max_fitness = V::MIN

      @selection[@selection_bots - 1].replace @bots.max_by(&.fitness) # Prevent stagnation if a previous leader does not hit target

      @before_simulation_action.try &.call(@generation, true)

      @bots.each { |bot|
        bot.fitness = V.new 0
        fitness = yield bot, @generation
        bot.fitness = fitness
        max_fitness = fitness if max_fitness < fitness
      }

      @fitness_history.shift if @fitness_history.size == SIMULATIONS_HISTORY
      @fitness_history << max_fitness

      @after_simulation_action.try &.call(@generation, true)
    end

    private def training_world_simulation(&block : Array(Bot(T, V)), UInt64 -> Void) : Void
      max_fitness = V::MIN

      @selection[@selection_bots - 1].replace @bots.max_by(&.fitness) # Prevent stagnation if a previous leader does not hit target

      @before_simulation_action.try &.call(@generation, true)

      @bots.each { |bot| bot.fitness = V.new 0 }
      yield @bots, @generation
      @bots.each { |bot| max_fitness = bot.fitness if max_fitness < bot.fitness }

      @fitness_history.shift if @fitness_history.size == SIMULATIONS_HISTORY
      @fitness_history << max_fitness

      @after_simulation_action.try &.call(@generation, true)
    end

    private def prepare_selection(best_previous : Bot(T, V)) : Void
      current_selection = 0
      @bots.sort { |bot1, bot2| bot2.fitness <=> bot1.fitness }.each { |bot|
        next if @selection.first(current_selection).count(&.same? bot) >= 3
        @selection[current_selection].replace bot
        current_selection += 1
        break if current_selection >= @selection_bots - 1
      }

      (current_selection + 1..@selection_bots - 1).each { |index| @selection[index].replace @bots.sample(@random) }

      @selection[-1].replace best_previous # Prevent stagnation if a previous leader does not hit target
    end

    private def process_evolution : Void
      # Replace all bots with copied selection
      selection_index = 0 # Optimization: `@selection[ current_selection % @selection_bots ]` works slower
      @bots.each { |bot|
        bot.replace @selection[selection_index]
        selection_index += 1
        selection_index -= @selection_bots if selection_index >= @selection_bots
      }

      crossover if @crossover_enabled
      mutate
      finalize_evolution
    end

    private def prevent_stagnation : Void
      @bots[@extra_evolution_bots].each { |bot|
        bot.genome.generate
        bot.crossover @selection.sample(@random) if @random.next_bool
        bot.generation = @generation
      }
    end

    private def bad_statistics? : Bool
      min = max = @fitness_history.first
      min_index = max_index = 0

      @fitness_history.each_with_index { |iteration, index|
        if min > iteration
          min = iteration
          min_index = index
        end

        if max < iteration
          max = iteration
          max_index = index
        end
      }

      max_index < SIMULATIONS_HISTORY * 0.5 && (min == max || min_index > SIMULATIONS_HISTORY * 0.6 && 100 - min * 100 / max > 20)
    end
  end
end

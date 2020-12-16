# YAGA - Yet Another Genetic Algorithm

YAGA is a genetic multilayer algorithm supporting different classes between layers.

* Engine has no dependencies instead of stdlib (only specific operations use it, see the documentation about each)
* YAGA has been made to support different classes for inputs, outputs and layers (like difference between convolutional and fully connected layers in CNNs)
* Genetic model generates on compile-time and does not consume initialization resources on production
* It can be used to train your models before production with `Population` class or to run the model with `Bot` class in production
* Saving and loading the model saves and loads the state of `Operation`s in each layer into JSON

## Index

* [Installation](#installation)
* [Usage](#usage)
   1. [Require the engine](#1-require-the-engine)
   2. [Compile genome model](#2-compile-genome-model)
   3. [Prepare the data](#3-prepare-the-data)
   4. [Create population based on compiled genome](#4-create-population-based-on-compiled-genome)
      * [Generic parameters](#generic-parameters)
      * [Initialization parameters (with defaults)](#initialization-parameters-with-defaults)
   5. [Train bots](#5-train-bots)
      * [Version 1: `#train_each`](#version-1-train_each)
      * [Version 2: `#train_world`](#version-2-train_world)
      * [Notes](#notes)
   6. [Take the leader](#6-take-the-leader)
   7. [Save/Load the state](#7-saveload-the-state)
   8. [Exploitation](#8-exploitation)
      * [Version 1: `#simulate_each`](#version-1-simulate_each)
      * [Version 2: `#simulate_world`](#version-2-simulate_world)
   9. [Population Callbacks](#9-population-callbacks)
   10. [Genetic functions](#10-genetic-functions)
* [Development](#development)
* [Contributing](#contributing)
* [Contributors](#contributors)

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     yaga:
       github: SlayerShadow/yaga
   ```

2. Run `shards install`

## Usage

* Please see the [examples](examples) folder with specific documentation about each use case provided by engine
* Please see the [chromosomes](src/yaga/chromosomes) folder with descriptions about each `Chromosome` in presets to understand which would be more useful for specific project

Basic usage taken from Lesson 1, full algorithm is located in [Horizontal-Vertical recognition](examples/horizontal_vertical) folder.

### 1. Require the engine

```crystal
require "yaga"
```

Chromosomes does not loads automatically - just a core engine.<br>
You can develop your own chromosomes for your project by inheriting from `YAGA::Chromosome` or by using presets in [chromosomes](src/yaga/chromosomes):

```crystal
require "yaga/chromosomes/binary_neuron"
```

Please read the documentation about chromosome.<br>
They could have external dependencies that should be added to your `shard.yml` (example: `MatrixMultiplicator` with requiring of `SimpleMatrix` shard).

### 2. Compile genome model

Genome builds on compile-time and based on `StaticArray`s to achieve the highest possible performance.

```crystal
YAGA::Genome.compile(
  # Generated genome class           Inputs type (array)       Inputs size
  BinaryGenome                     , BitArray                , 9          ,

  # Activator                        Activations type (array)  Outputs size
  { YAGA::Chromosomes::BinaryNeuron, BitArray                , 4            },
  { YAGA::Chromosomes::BinaryNeuron, BitArray                , 2            }
)
```

1. `BinaryGenome` is a class name of building genome. It can be any that Crystal supports.
2. `BitArray` - the type of input that the model works with. Should be an array (`StaticArray`/`Array`/`Set`/etc that has `#[]`, `#[]=` and `<<` methods).
3. `9` - number of elements that passes in.
4. `{ Chromosome, output_type, output_amount }` - genome layers:
   1. `YAGA::Chromosomes::BinaryNeuron` - chromosome class. Internally should have the same inputs type as outputs of previous layer. In case of the first layer after inputs - should have the inputs type.
   2. `BitArray` - layer's outputs type. Like an inputs, should be an array.
   3. `4` - number of outputs (note that inputs are taken from outputs of the layer before).

As you can see, like a neural networks each layer (i.e. each `Chromosome`) can manage its own data types. Please see [examples](examples) for more complicated use cases.

### 3. Prepare the data

```crystal
inputs = Array( BitArray ).new( 16 ){ BitArray.new 9 }
outputs = Array( BitArray ).new( 16 ){ BitArray.new 2 }
```

Please note that array of inputs has the same size as the model inputs; array of outputs - the same as model outputs.

Fill the inputs and outputs somehow (for example it can be the [horizontal and vertical recognition example](examples/horizontal_vertical/data.cr#L47)).

### 4. Create population based on compiled genome

```crystal
random = Random.new

# Arguments are:
# 1. Total Population
# 2. Selection
# 3. Mutation Chance
# 4. Should crossover be enabled
# 5. Custom random for deterministic behaviour
population = YAGA::Population( BinaryGenome, UInt32 ).new 64_u32, 8_u32, 10_u8, true, random
```

It is also available to initialize population with named arguments:

```crystal
random = Random.new
population = YAGA::Population( BinaryGenome, UInt32 ).new total_bots: 64_u32,
                                                          selection_bots: 8_u32,
                                                          mutation_percent: 10_u8,
                                                          crossover_enabled: true,
                                                          random: random
```

#### Generic parameters

* `BinaryGenome` - the compiled genome class name (required)
* `UInt32` - the type of the fitness value (any `Number` type) (required) _Please see different examples why it is here_

#### Initialization parameters (with defaults)

* `total_bots`: `64_u32` - total population amount
* `selection_bots`: `8_u32` - selection amount that will be chosen as best (see [Genetic Algorithm](https://wiki2.org/en/Genetic_algorithm+Newton#Selection) articles to understand what is selection)
* `mutation_percent`: `10_u8` - mutation percent (see [Genetic Algorithm](https://wiki2.org/en/Genetic_algorithm+Newton#Selection) articles to understand what is mutation)
* `crossover_enabled`: `true` - set it to `false` if crossover action should be disabled
* `random`: `Random::DEFAULT` - if the trainig population needs to be deterministic (see [Example 3 - Snake Game](examples/snake_game))

### 5. Train bots

Samples in this section based on [Example 1 - Horizontal-Vertical](examples/horizontal_vertical) and its BitArray `inputs` vector.

#### Version 1: `#train_each`

```crystal
# It would be better to see the progress
require "progress"

goal = 16 # Please make sure the type is matched to population fitness type
generation_cap = 30000_u64

bar = ProgressBar.new( ( generation_cap * population.total_bots ).to_i )

simulations_passed = population.train_each( goal, generation_cap ){|bot, generation|
  fitness = 0 # How good the bot is

  inputs.each_with_index{|input, index|
    activation = bot.activate input # Last genome layer calculation result
    fitness += 1 if activation == outputs[ index ] # Calculate fitness
  }

  bar.inc

  fitness
}

p simulations_passed: simulations_passed # Amount of simulations
```

* Block is the main algorithm that applies to each bot in population
* The block's argument is a [`YAGA::Bot( T )`](src/yaga/bot.cr) with the same type as genome input (`BinaryGenome` in this example)
* Output of the block call should be Float64 fitness value: more fitness value -> more suitable bot
* Output of the training process (`simulations_passed`) is the total simulations that bots passed
* `goal` (required) - training stops when any bot reaches the goal
* `generation_cap` (optional, 10 000 by default) - total simulations amount which should be passed before stop, prevents infinity loop when bots cannot reach the goal
* `progress` is not required feature but it helps a lot in training
   * Please make sure to add `askn/progress` into your `shards.yml`

#### Version 2: `#train_world`

```crystal
# It would be better to see the progress
require "progress"

def run_simulation( bots : Array( BinaryGenome ), inputs : Array( BitArray ) ) : Void
  bots.each{|bot|
    fitness = 0 # How good the bot is

    inputs.each_with_index{|input, index|
      activation = bot.activate input # Last genome layer calculation result
      fitness += 1 if activation == outputs[ index ] # Calculate fitness
    }

    bot.fitness = fitness
  }
end

goal = 16 # Please make sure the type is matched to population fitness type
generation_cap = 30000_u64

bar = ProgressBar.new generation_cap.to_i

simulations_passed = population.train_world( goal, generation_cap ){|bots, generation|
  run_simulation bots, inputs
  bar.inc
}

p simulations_passed: simulations_passed # Amount of simulations
```

#### Notes

* You can see the difference in [Example 1 - Horizontal-Vertical](examples/horizontal_vertical)
* [Example 2 - Quadratic Equation](examples/quadratic_equation) is written only with `#train_each`
* [Example 3 - Snake Game](examples/snake_game) is written only with `#train_world`
* Instead of launching `population.train_*( ... ){ ... }` methods, a `population.evolve!` method can be called explicitly if the app does not compliant with standard training process

### 6. Take the leader

```crystal
bot = population.selection.first
dna_genes = bot.genome.dna.map{ |chromosomes| chromosomes.map{ |chromosome| chromosome.genes } }

p genome: dna_genes,
  generation:  bot.generation, # Bot generation - on what simulation appeared bot's genome state
  max_fitness: bot.fitness,    # Bot's personal training fitness result (on the last simulation)
  brain_size:  bot.brain_size  # Total number of genes
```

### 7. Save/Load the state

```crystal
# To save genome - just say the bot to show json
best = population.bots.max_by &.fitness
genome = best.to_json
p genome

# To restore genome - just say the bot to read json
bot = YAGA::Bot( BinaryGenome, UInt32 ).from_json genome

# To restore the same genome for all population - apply the loaded bot's genome to this
population.bots.each &.replace( bot )
```

There is no option to load genome into population itself. Please see [Example 3 - Snake Game](examples/snake_game) about that.<br>
In short - `from_json` works completely correctly and stable only for `YAGA::Bot` class itself, it is not responsible for programmer-defined classes (like a `Game::Snake` class in described example).

`to_json` have less problems with that - until it is redefined in custom classes. And can be used on subclasses of `YAGA::Bot` directly.

### 8. Exploitation

```crystal
# Get a bot result:
p bot.activate( inputs.sample )
```

#### Version 1: `#simulate_each`

```crystal
input = inputs.sample

# Launch the population simulation per bot:
population.simulate_each{|bot|
  p bot.activate( input )
}
```

#### Version 2: `#simulate_world`

```crystal
input = inputs.sample

# Launch the population simulation for all bots:
population.simulate_world{|bots|
  p bots.map( &.activate( input ) )
}
```

### 9. Population Callbacks

Each callback can be defined at any time and assigns to `population` object.

Callbacks will be launched in the same order as mentioned.

* `before_training( &block : UInt64, V, UInt64 -> Void ) : Void` - assigns callback which launches before starting the training ran via `train_*` methods
* `before_simulation( &block : UInt64 -> Void ) : Void` - assigns callback which launches before every simulation ran via `#simulate_*` and `train_*` methods
* `before_evolution( &block : UInt64 -> Void ) : Void` - assigns callback which launches before every training ran via `train_` methods
* `after_evolution( &block : UInt64 -> Void ) : Void` - assigns callback which launches before every training ran via `train_` methods
* `after_simulation( &block : UInt64 -> Void ) : Void` - assigns callback which launches before every simulation ran via `#simulate_*` and `train_*` methods
* `after_training( &block : UInt64, V, UInt64 -> Void ) : Void` - assigns callback which launches before every simulation ran via `#simulate_*` and `train_*` methods

All methods yield population generation on the first argument.<br>
Only one callback of the same type can be assigned at the same time (it is not possible to define double `before_simulation` callbacks and etc.).

`before_training` and `after_training` arguments:

* current population generation
* fitness goal of training (type V - user-defined on population initialization)
* generations amount that should be trained (or has been trained - if it is `after_training` callback)

Example:

```crystal
bar = ProgressBar.new 0

# Define before_training callback and reset progress bar size
population.before_training{|generation, goal, training_generations|
  # Show some statistics before training
  p previons_generation: generation, goal_to_train: goal, training_generations: training_generations

  bar.total = training_generations.to_i32
  bar.set 0
}

# Show evolutions statistics (warning: it is calling per each simulation on evolution process)
population.after_evolution{|generation|
  # It is possible to see some statistics
  # p new_generation: generation, max_fitness: population.selection.max_by( &.fitness )
  # but using progress bar can be more viable
  bar.inc
}

population.train_world( goal: 1.2, generation_cap: 10000 ){|bots, generation|
  # ...training logic...
}
```

### 10. Genetic functions

If you'd like to use your own genetic functions it is possible to override the default ones or create the inherited class:

```crystal
class CustomPopulation < YAGA::Population( MyDNA, Float64 )
  def crossover : Void
    # Write your crossover function here
  end

  def mutate : Void
    # Write your mutation algorithm here
  end

  def finalize_evolution : Void
    # By default, this overrides last 5 bots to prevent stagnation
    # You can leave it empty if it is not needed in your case
  end
end
```

## Development

All PRs are welcome!

* To add the chromosome, please add it to `src/chromosomes` folder
* Please make sure that features compile with `--release` and (preferably) `--static` flags on Alpine Linux (see the `Dockerfile` sample for clarification)
* Please make sure that it is working correctly when composed with other existed chromosomes when layered it in mixed way
* Please add at least one spec and at least one example to clarify its use cases
* Please note about secific inputs or outputs for the chromosome (such as `YAGA::Chromosomes::BinaryNeuron` based on `BitArray`) in example documentation. It would also help users to architect interfaces more strict and less error prone.
* Please add your name to contributors list below to make a history

## Contributing

1. Fork it (<https://github.com/SlayerShadow/yaga/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [SlayerShadow](https://github.com/SlayerShadow) - creator and maintainer

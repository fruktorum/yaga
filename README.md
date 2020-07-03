# YAGA - Yet Another Genetic Algorithm

YAGA is a genetic multilayer algorithm supporting different classes between layers.

* Engine has no dependencies instead of stdlib (only specific operations use it, see the documentation about each)
* YAGA has been made to support different classes for inputs, outputs and layers (like difference between convolutional and fully connected layers in CNNs)
* Genetic model generates on compile-time and does not consume initialization resources on production
* It can be used to train your models before production with `Population` class or to run the model with `Bot` class in production
* Saving and loading the model saves and loads the state of `Operation`s in each layer into JSON

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
population = YAGA::Population( BinaryGenome ).new 256_u32, 12_u32
```

* `BinaryGenome` - the compiled genome class name
* `256_u32` - total population amount (optional)
* `12_u32` - selection amount that will be chosen as best (optional) (see [Genetic Algorithm](https://wiki2.org/en/Genetic_algorithm+Newton#Selection) articles to understand what is selection)

### 5. Train bots

#### Version 1: `#train_each`

```crystal
# It would be better to see the progress
require "progress"

fitness_target = 16_f64
simulations_cap = 30000_u64

bar = ProgressBar.new( ( simulations_cap * population.total_bots ).to_i )

simulations_passed = population.train_each( fitness_target, simulations_cap ){|bot|
  fitness = 0_f64 # How good the bot is

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
* `fitness_target` (required) - training stops when any bot achieves the target
* `simulations_cap` (optional, 10 000 by default) - total simulations cap, - training stops when target is not achieved for the number of simulations
* `progress` is not required feature but it helps a lot in training
   * Please make sure to add `askn/progress` into your `shards.yml`

#### Version 2: `#train_world`

```crystal
# It would be better to see the progress
require "progress"

def run_simulation( bots : Array( BinaryGenome ), inputs : Array( BitArray ) ) : Void
  bots.each{|bot|
    fitness = 0_f64 # How good the bot is

    inputs.each_with_index{|input, index|
      activation = bot.activate input # Last genome layer calculation result
      fitness += 1 if activation == outputs[ index ] # Calculate fitness
    }

    bot.fitness = fitness
  }
end

fitness_target = 16_f64
simulations_cap = 30000_u64

bar = ProgressBar.new simulations_cap.to_i

simulations_passed = population.train_world( fitness_target, simulations_cap ){|bots|
  run_simulation bots, inputs
  bar.inc
}

p simulations_passed: simulations_passed # Amount of simulations
```

#### Note

* You can see the difference in [Example 1 - Horizontal-Vertical](examples/horizontal_vertical)
* [Example 2 - Quadratic Equation](examples/quadratic_equation) is written only with `#train_each`
* [Example 3 - Snake Game](examples/snake_game) is written only with `#train_world`
* Instead of launching `population.train_*( ... ){ ... }` methods, a `population.evolve!` method can be called explicitly if the app does not compliant with standard training process

### 6. Take the leader

```crystal
bot = population.selection.first
genes = bot.genome.chromosome_layers.map{ |chromosomes| chromosomes.map{ |chromosome| chromosome.genes } }

p genome: genes,
  generation:  bot.generation, # Bot generation - on what simulation appeared bot's genome state
  max_fitness: bot.fitness,    # Bot's personal training fitness result (on the last simulation)
  brain_size:  bot.brain_size  # Number of genes
```

### 7. Save the state

TODO: Plan to add `#from_json` and `#to_json` for `Genome` and `Chromosome` abstract classes.

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

### 9. Features

Described callbacks will be launched in the same order as mentioned:

* `population.before_simulation( &block : UInt64 -> Void ) : Void` - assigns callback which launches before every simulation ran via `#simulate_*` and `train_*` methods
* `population.before_evolution( &block : UInt64 -> Void ) : Void` - assigns callback which launches before every training ran via `train_` methods
* `population.after_evolution( &block : UInt64 -> Void ) : Void` - assigns callback which launches before every training ran via `train_` methods
* `population.after_simulation( &block : UInt64 -> Void ) : Void` - assigns callback which launches before every simulation ran via `#simulate_*` and `train_*` methods

All methods yield population generation.<br>
Only one callback can be assigned at the same time.

Example:

```crystal
population.after_evolution{|generation|
  p new_generation: generation, max_fitness: population.bots.max_by( &.fitness )
}
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

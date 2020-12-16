# Formula recognition

Try to find the formula by array of it results.

* Inputs (1 activation): `x`
* Prediction (1 activation): `y`
* Goal: find a formula tree for ![y = f(x)](https://latex.codecogs.com/gif.latex?y%20%3D%20f%28x%29 "y = f(x)")
* Loss: MSE algorithm ![(1 / N) sum( (prediction - actual) ** 2 )](https://latex.codecogs.com/gif.latex?%5Cfrac%7B1%7D%7BN%7D%20%5Csum_%7Bi%20%3D%201%7D%5E%7BN%7D%20%28prediction_i%20-%20actual_i%29%5E%7B2%7D "(1 / N) sum( (prediction - actual) ** 2 )"), where `N` is amount of training values.

Model builds the syntax tree of the function ![y = f(x)](https://latex.codecogs.com/gif.latex?y%20%3D%20f%28x%29 "y = f(x)") using its own chromosome.

## Index

* [Data explanation](#data-explanation)
   * [Equation](#equation)
* [Genetic modelling](#genetic-modelling)
   1. [Initialization](#1-initialization)
   2. [Extend existing chromosomes](#2-extend-existing-chromosomes)
   3. [Compile the model](#3-compile-the-model)
   4. [Initialize the population](#4-initialize-the-population)
   5. [Train bots](#5-train-bots)
   6. [Analytics](#6-analytics)
   7. [Usage](#7-usage)
* [Genetic solutions](#genetic-solutions)
* [Actual function used in example](#actual-function-used-in-example)

## Data explanation

* We have an unknown function
* We can feed function the value below than 2-bytes Integer and it returns an Integer
* Assume that x has random nature - feeded once, next function input will be different

### Equation

[Equation](../../src/yaga/chromosomes/equation.cr) is the syntax analyzer that builds a function graph from a "chromosome".

All available parts of a "chromosome" and building mechanics are shown in the source file. More detailed description how it works can be found in [articles](https://ruslanspivak.com/lsbasi-part7).

## Genetic modelling

### 1. Initialization

```crystal
# Used for MSE calculations - prevent Arithmetic Overflow error
require "big/big_float"

# Watch the progress
require "progress"

# Engine
require "yaga"

# Need a preset with "Equation" chromosome
require "./genetic/equation"
```

### 2. Extend existing chromosomes

Equation works with Float64 but in term of challenge we should use UInt16 for input and UInt64 for output.

Also the challenge says that we have a quadratic equation, so we do not need a complete set of functions provided by `Equation`.

So we need to extend `Equation` for a bit; it also speeds up performance.

```crystal
class QuadraticEquation < YAGA::Chromosomes::Equation
  # Reduce chromosome size from defaults to 15
  # And use only specific functions parts: Neg, Sum, Mul, Const(1), Const(2), x
  def initialize( num_inputs : Int32 )
    super num_inputs, 15_u8, Array( UInt8 ){ 0, 1, 2, 3, 4, 5 }
  end

  # Instead of floats, use UInt16 as inputs and Int64 for outputs (output can be really huge)
  def activate( inputs : Array( UInt16 ) ) : Int64
    @tree.eval( inputs[ 0 ].to_f64 ).to_i64
  end
end
```

### 3. Compile the model

```crystal
YAGA::Genome.compile(
  QuadraticGenome, # Name of the new model

  # Inputs type    Inputs size
  Array( UInt16 ), 1          ,

  # Activator          Activations type  Outputs size
  { QuadraticEquation, Array( Int64 )  , 1            }
)
```

### 4. Initialize the population

```crystal
#                                                             Population, Selection, Mutation Percent
population = YAGA::Population( QuadraticGenome, Float64 ).new 256_u32   , 12_u32   , 100_u8
```

### 5. Train bots

Please see [train.cr](train.cr) source for the full training process.

In short:

```crystal
# Pass all inputs/outputs (inner loop) via each bot (outer loop)
population.train_each( 1, simulations_cap ){|bot|
  # Use inversed Mean Squared Error for the fitness value
  mse = BigFloat.new 0

  inputs.each_with_index{|input, index|
    output = inputs[ index ]

    # Assume that 'input' is UInt16, so pass the array
    # Because result of the function is array with only one element, use it explicitly
    activation = bot.activate( [ input ] ).first

    mse += ( ( output - activation ).to_big_f ** 2 ) / inputs.size
  }

  # Result of the 'train_each' block should be the fitness of the bot
  ( 1 / ( mse + 1 ) ).to_f64
}
```

### 6. Analytics

Show info about a top bot (winner).

* `selection` is the special object in population that contains top winners
* In the example it is an `Array( Bot )` with 8 entities sorted by fitness
* `genes` object is an `Array( Array( QuadraticEquation ) )` in case of example
   * Outer array contains layers
   * Inner arrays contain chromosomes and directly executable commands

```crystal
bot = population.selection.first

p genes: bot.genome.dna.first.first.genes
p generation: bot.generation, max_fitness: bot.fitness, brain_size: bot.brain_size
p bot.to_json
```

### 7. Usage

```crystal
32.times{
  input = rand 128_u16
  output = f input

  p input: input, prediction: bot.activate( [ input ] )[ 0 ], actual: output
}
```

## Genetic solutions

For a bunch of runs all solutions are started with value "1". With chromosome of length 15 there is not so much solutions variants.

* `[[1, 4, 2, 0, 5, 1, 1, 0, 1, 4, 2, 4, 3, 5]]`
* `[[1, 0, 1, 5, 4, 0, 2, 1, 5, 0, 1, 1, 4, 4, 5]]`
* `[[1, 2, 4, 5, 1, 3, 1, 2, 5, 4, 1, 0, 0, 4, 3]]`

Let's examine the first solution in detail.

```
Chromosome: 1 4 2 0 5 1 1 0 1 4 2 4 3 5
Operation:  + 2 * N x + + N + 2 * 2 1 x
Arity:      2 0 2 1 0 2 2 1 2 0 2 0 0 0

Tree:

      +
     / \
    2   *
       / \
      N   x
      |
      +
     / \
    +   N
   / \   \
  +   2   *
 / \     / \
2   1   x   ?
```

There is one empty leaf. It means that bot's architecture is not 100% optimal and chromosome length can be decreased at least by 1 (from 14 to 13 genes).

Parse the tree:

![2 + ( x * ( -(-x + 5) ) ) = 2 + ( x * (x - 5) ) = 2 + x ^ 2 - 5x](https://latex.codecogs.com/gif.latex?2%20&plus;%20%28%20x%20*%20%28%20-%20%28-x%20&plus;%205%29%20%29%20%29%20%3D%202%20&plus;%20%28x%20*%20%28x%20-%205%29%29%20%3D%202%20&plus;%20x%5E2%20-%205x "2 + ( x * ( -(-x + 5) ) ) = 2 + ( x * (x - 5) ) = 2 + x ^ 2 - 5x")

## Actual function used in example

It is placed to [data.cr](data.cr) in current example.

![y = x ^ 2 - 5x + 2](https://latex.codecogs.com/gif.latex?y%20%3D%20x%5E%7B2%7D%20-%205x%20&plus;%202 "y = x ^ 2 - 5x + 2")

```crystal
def f( x : UInt16 ) : Int64
  x.to_i64 ** 2_i64 - 5_i64 * x.to_i64 + 2_i64
end
```

It can be used directly or for generating a dataset with input and output pairs, it not actually matters, bots will find solution even with a sequence of three values.

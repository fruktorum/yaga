# Quadratic Equation

Try to find the formula by array of it results.

* Inputs (1 activation): `x`
* Prediction (1 activation): `y`
* Goal: find a formula tree for ![y = f(x)](https://latex.codecogs.com/gif.latex?y%20%3D%20f%28x%29 "y = f(x)")
* Loss: MSE algorithm ![(1 / N) sum( (prediction - actual) ** 2 )](https://latex.codecogs.com/gif.latex?%5Cfrac%7B1%7D%7BN%7D%20%5Csum_%7Bi%20%3D%201%7D%5E%7BN%7D%20%28prediction_i%20-%20actual_i%29%5E%7B2%7D "(1 / N) sum( (prediction - actual) ** 2 )"), where `N` is amount of training values.

Model builds the syntax tree of the function ![y = f(x)](https://latex.codecogs.com/gif.latex?y%20%3D%20f%28x%29 "y = f(x)") using its own chromosome.

## Data explanation

* We have an unknown function
* We can feed function the value below than 2-bytes Integer and it returns an Integer
* Assume that x has random nature - feeded once, next function input will be different

### Equation

[Equation](../../src/yaga/chromosomes/equation.cr) is the syntax analyzer that builds a function graph from a "chromosome".

All available parts of a "chromosome" and building mechanics are shown in the source file. More detailed description how it works can be found in [articles](https://ruslanspivak.com/lsbasi-part7).

## Genetic modelling

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

Equation works with Float64 but in term of challenge we should use UInt16 for input and UInt64 for output.

Also the challenge says that we have a quadratic equation, so we do not need a complete set of functions provided by `Equation`.

So we need to extend `Equation` for a bit; it also speeds up performance.

```crystal
class QuadraticEquation < Equation
  # Reduce chromosome size from defaults to 15
  # And use more specific functions parts: Neg, Sum, Mul, 1, 2, x
  def initialize( num_inputs : Int32 )
    super num_inputs, 15_u8, Array( UInt8 ){ 0, 1, 2, 3, 4, 5 }
  end

  # Instead of floats, use UInt16 as inputs and Int64 for outputs (output can be really huge)
  def activate( inputs : Array( UInt16 ) ) : Int64
    @tree.eval( inputs[ 0 ].to_f64 ).to_i64
  end
end
```

Compile the model.

```crystal
YAGA::Genome.compile(
  QuadraticGenome, # Name of new model

  # Inputs type        Inputs size
  Array( UInt16 )    , 1               ,

  # Activator          Activations type  Outputs size
  { QuadraticEquation, Array( Int64 )  , 1            }
)
```

Initialize the population based on this model.

```crystal
#                                                    Population, Selection
population = YAGA::Population( QuadraticGenome ).new 256_u32   , 8_u32
```

Train bots.

```crystal
simulations_cap = 30000

# For the progress
bar = ProgressBar.new( ( simulations_cap * population.total_bots ).to_i )

# Cache for max MSE that some bot had
max_mse = BigFloat.new 0

# Set "1" for fitness because of MSE: max fitness can be achieved when bot's results
# are fully match with function's results. This means bot found this function,
# its error equals 0 and fitness equals 1.
simulations = population.train( 1, simulations_cap ){|bot|
  mse = BigFloat.new 0 # MSE can be huge in this example. Very huge.

  8.times{
    input = rand 128_u16
    output = f input

    # Input is a scalar. System needs a vector.
    # System' output is a vector. MSE needs scalar.
    # Wrap input in brackets and get first element from the output.
    activation = bot.activate( [ input ] )[ 0 ]

    # MSE = sum_per_elements( ( actual - prediction ) ^ 2 )
    mse += ( output - activation ).to_big_f ** 2
  }

  max_mse = mse if max_mse < mse

  bar.inc

  # We calculated MSE.
  # But we need a fitness of the bot that can be presented like 1 / MSE.
  # Because MSE can be 0, add 1 to denominator to prevent division by zero.
  # Result is the value between 0 and 1.
  ( 1 / ( mse + 1 ) ).to_f64
}

bar.print

p max_mse: max_mse
```

Show info about a top bot (winner).

* `selection` is the special object in population that contains top winners
* In the example it is an `Array( Bot )` with 8 entities sorted by fitness
* `genes` object is an `Array( Array( QuadraticEquation ) )` in case of example
   * Outer array contains layers
   * Inner arrays contain chromosomes and directly executable commands

```crystal
bot = population.selection.first

p genome: bot.genome.genes[ 0 ].map( &.weights )
p generation: bot.generation, max_fitness: bot.fitness, brain_size: bot.brain_size
```

Test bot predictions.

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

## Actual function used in example

![y = x ^ 2 - 5x + 2](https://latex.codecogs.com/gif.latex?y%20%3D%20x%5E%7B2%7D%20-%205x%20&plus;%202 "y = x ^ 2 - 5x + 2")

```crystal
def f( x : UInt16 ) : Int64
  x.to_i64 ** 2_i64 - 5_i64 * x.to_i64 + 2_i64
end
```

It can be used directly or for generating a dataset with input and output pairs, it not actually matters, bots will find solution even with a sequence of three values.
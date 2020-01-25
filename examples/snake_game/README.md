# Convolutional Snake AI

Classical Snake Game with modifications.

## External dependencies

If example launches from a root lib folder, please run `shards install`, it installs development dependencies that will be enough.

In any case it uses:

* SimpleMatrix - matrix calculations required for [Matrix](../../src/yaga/chromosomes/matrix.cr) chromosome
* Tilerender - output interfaces to render simple colorized graphics; this example uses command-line interface to write STDOUT

## Challenge description

* Snake vision is capped by 5 squares in each direction _(11x11 = 121 field of view)_
* Snake can move by 3 directions: move forward, turn left, turn right
* Each turn Snake moves by 1 square
* Snake eats Food and grows by 1 square
* Snake dies when Food has not been found in 180 steps
* Steps counter resets to 180 when Snake finds Food
* Snake dies when collides with tail, other Snake or wall

* The Field has 136x35 dimensions
* The Field contains 32 Snakes and 35 Food _(1 Food per 136 squares, more than Snake's field of view)_
* There are 8 Fields for the training _(which are in total contain population of 256 Snakes)_
* Demonstration Field contains 32 Snakes with single best trained DNA, or with uploaded DNA if the training has been skipped

The challenge directed not to fill all space but to find a Food as soon as possible.

## DNA mechanics

The challenge can be solved in a lot of different ways.<br>
But to have an idea of all features of the genetic engine there is used Convolutional sensors.<br>
Mostly it looks like a Convolutional Neural Network (discrete CNN because of `Int32` parameters type).

### Receptive field

```
_______________________
|x| | | | | | | | | | |
|x| | | | | | | | | | |
|x| | | | | | | |F| | |
| | | | | | | | | | | |
| | | | | | | | | | | |
| | | | | |x| | | | | |
| | | | | |x| | | | | |
| | | | | |x| | | | | |
| | | | | |x|x| | | | |
| | | | | | | | | | | |
|_|_|_|_|_|_|_|_|_|_|_|
```

* In relation to the Receptive Field Snake always watch forward (to the top)
* Snake's head is always centered on Receptive Field
* `x` means that snake own tail, other snake's tail or wall is located on this position
* `F` means a food is located on this postion
* _Empty_ square means an empty space with no objects

### 0. Input

Genome input is an 11x11 matrix of signed Int32 with values:

* `0` - empty space
* `2` - food
* `-1` - wall
* `-2` - obstacle (snake tail or head)

### 1. Convolutional layers

Layers based on [Matrix](../../src/yaga/chromosomes/matrix.cr) chromosome.

3 layers with 3, 3 and 9 chromosomes accordingly.<br>
Input - Int32 Matrix, output - Int32 Matrix (each chromosome).

Convolutions (and, in general, matrix) layers use Matrix chromosome:

```crystal
require "yaga/chromosomes/matrix"
```

This structure should decrease dimensions and allow snake to recognize patterns.<br>
It is used signed Int32 type to have a viable calculation range; it does not use Floats to make a system well-optimized.

```crystal
class Convolution < YAGA::Chromosomes::Matrix( Int32, Array( SimpleMatrix( Int32 ) ), SimpleMatrix( Int32 ) )
  def initialize( @num_inputs, @layer_index, @chromosome_index )
    # Kernel has constantly defined size for all layers and equals to 3x3
    @genes = SimpleMatrix( T ).new 3, 3

    # Convolution result per layer: fields 9x9, 7x7 and 5x5 for each layer accordingly
    @results = SimpleMatrix( T ).new 9 - @layer_index * 2, 9 - @layer_index * 2

    # It is not needed to have a high evolution range
    @random_range = -3 .. 3
    randomize
  end

  def activate( inputs : U ) : V
    # For the first layer (3 chromosomes) it convolves only one input
    # For the second layer (3 chromosomes) it convolves previous layer with the same chromosome index
    # For the third layer (9 chromosomes) it convolves each previous layer sequentially the triads
    inputs[ @chromosome_index % inputs.size ].convolve @genes, @results

    # The engine result converter macros
    prepare_result
  end
end
```

### 2. Matrix multiplication layer

Layer based on [Matrix](../../src/yaga/chromosomes/matrix.cr) chromosome.

1 layer with 3 chromosomes.
Input - Int32 Matrix, output - Float64 Array (each chromosome).

The last 9 convolutional results (recognized patterns) will be merged the triads and multiplied by the layer's chromosome.

```crystal
class DotMatrix < YAGA::Chromosomes::Matrix( Int32, Array( SimpleMatrix( Int32 ) ), Array( Float64 ) )
  def initialize( @num_inputs, @layer_index, @chromosome_index )
    # Dot product of 5x5 matrix with 5x1 matrix makes result a 5x1 matrix
    @genes = SimpleMatrix( T ).new 5, 1
    @results = SimpleMatrix( T ).new 5, 1

    # In result of decreased dimensions the genes range can be extended without performance loss
    @random_range = -5 .. 5
    randomize
  end

  # Apply each multiplication to sum of 3 convolution results
  def activate( inputs : U ) : V
    sum_inputs = SimpleMatrix( T ).new inputs.first.height, inputs.first.width

    3.times{ |index| sum_inputs.sum inputs[ index * 3 + @chromosome_index ], sum_inputs }
    sum_inputs.dot @genes, @results

    # Convert 5x1 matrix to 1D Float64 vector with 5 elements
    @results.buffer.map{ |row| row[ 0 ].to_f64 }
  end
end
```

### 3. Equation layer

Layer based on [Equation](../../src/yaga/chromosomes/equation.cr) chromosome.

1 layer with 3 chromosomes.
Input - Float64 Array, output - 3 elements of Float64 (full layer).

To use the equations chromosome proposed by the engine, first it has to be required.

```crystal
require "yaga/chromosomes/equation"
```

Apply random function (depending on evolution) to each previous multiplication after squashing.<br>
Having 3 chromosomes in layer gives a high variety of applying functions. Bet the system can find optimal values.

Each chromosome has 10 genes and supports limited functions variation: `neg(a)`, `sum(a,b)`, `mul(a,b)`, `1`, `2`, `x`, `pi`, `sin(a)`, `cos(a)`, `log2(a)`.<br>
Full list of functions and description how does it work placed in sources of [Equation](../../src/yaga/chromosomes/equation.cr) chromosome.

Chromosomes apply their formulas with specific rule: ![Y = f(sum_i inputs_i)](https://latex.codecogs.com/gif.latex?Y%20%3D%20f%28%5Csum_%7Bi%20%3D%200%7D%5E%7Bn%20-%201%7D%20inputs_%7Bi%7D%29 "Y = f(sum_i inputs_i)").<br>
It can be patched to: ![Y = sum_i f(inputs_i)](https://latex.codecogs.com/gif.latex?Y%20%3D%20%5Csum_%7Bi%20%3D%200%7D%5E%7Bn%20-%201%7D%20f%28inputs_%7Bi%7D%29 "Y = sum_i f(inputs_i)"), but it works with the same quality.

```crystal
class Equation < YAGA::Chromosomes::Equation
  def initialize( num_inputs, layer_index, chromosome_index )
    super num_inputs, layer_index, chromosome_index, 10_u8, Array( UInt8 ){ 0, 1, 2, 3, 4, 5, 6, 8, 9, 11 }
  end

  def activate( inputs : Array( Array( Float64 ) ) ) : Float64
    @tree.eval inputs[ @chromosome_index ].reduce( 0_f64 ){ |result, value| result + value }
  end
end
```

### 4. Compile

```crystal
YAGA::Genome.compile(
  DNA, Array( SimpleMatrix( Int32 ) ), 1,

  { Convolution, Array( SimpleMatrix( Int32 ) ), 3 },
  { Convolution, Array( SimpleMatrix( Int32 ) ), 3 },
  { Convolution, Array( SimpleMatrix( Int32 ) ), 9 },
  { DotMatrix, Array( Array( Float64 ) ), 3 },
  { Equation, Array( Float64 ), 3 }
)
```

_Please note that all of these classes and compilation step is shown for readable example; it does not match example classes itself.<br>
To see all valid structure for this lesson please see the [Snake DNA file](genetic/dna.cr)._

## Training

The training process is not much different from previous examples. Please see the Snake Game [training method](snake_game.cr#L13) itself for detailed explanation.

The only thing is the example uses `population.train_world( fitness, generation ){ |bots| }` function that splits training by simulations.

## Evolution results

To have a viable results it is better to compile example in production mode and launch the training in several processes.

There are trained DNAs that achieved 5 000 points in fitness function and can maximum reach over 10 000 points.<br>

### 1. 9 000 fitness max (7 000 fitness average)

```json
{"dna":[[{"genes":[[-1,3,4,0,3],[-4,-1,-3,2,-4],[-1,-2,0,-1,-1],[-3,-5,-3,1,-2],[-5,0,-3,3,-5]],"results_dimensions":{"height":7,"width":7},"random_range":{"from":-5,"to":5},"num_inputs":1,"layer_index":0,"chromosome_index":0},{"genes":[[-1,4,-4,-5,5],[-5,-5,0,1,3],[4,4,0,3,5],[3,3,1,-3,5],[-4,2,0,-3,-4]],"results_dimensions":{"height":7,"width":7},"random_range":{"from":-5,"to":5},"num_inputs":1,"layer_index":0,"chromosome_index":1},{"genes":[[-2,-4,-5,1,-1],[5,-5,-4,0,-4],[-1,-4,4,-2,1],[-4,2,3,-3,4],[-1,-2,2,3,-1]],"results_dimensions":{"height":7,"width":7},"random_range":{"from":-5,"to":5},"num_inputs":1,"layer_index":0,"chromosome_index":2}],[{"genes":[[2,-5,4],[-5,-4,-5],[5,-3,0]],"results_dimensions":{"height":5,"width":5},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":1,"chromosome_index":0},{"genes":[[2,-1,4],[3,0,-5],[3,3,2]],"results_dimensions":{"height":5,"width":5},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":1,"chromosome_index":1},{"genes":[[3,2,5],[3,4,1],[3,2,4]],"results_dimensions":{"height":5,"width":5},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":1,"chromosome_index":2}],[{"genes":[[4,5,-3],[0,2,3],[-1,-3,1]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":0},{"genes":[[3,5,2],[-1,-3,1],[4,0,4]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":1},{"genes":[[-4,3,-4],[4,-1,3],[1,-4,3]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":2},{"genes":[[-3,4,-4],[-5,-5,-3],[1,-1,5]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":3},{"genes":[[-2,-3,-2],[5,-2,1],[2,4,5]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":4},{"genes":[[0,-3,-3],[5,-2,2],[-3,-5,-1]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":5},{"genes":[[0,1,2],[-5,-4,-4],[-2,0,0]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":6},{"genes":[[-3,-5,4],[-3,3,3],[-2,-4,-2]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":7},{"genes":[[-5,-3,5],[-2,2,3],[-3,-1,4]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":8}],[{"genes":[[1],[-1],[0]],"results_dimensions":{"height":3,"width":1},"random_range":{"from":-5,"to":5},"num_inputs":9,"layer_index":3,"chromosome_index":0},{"genes":[[0],[-5],[-4]],"results_dimensions":{"height":3,"width":1},"random_range":{"from":-5,"to":5},"num_inputs":9,"layer_index":3,"chromosome_index":1},{"genes":[[-2],[4],[2]],"results_dimensions":{"height":3,"width":1},"random_range":{"from":-5,"to":5},"num_inputs":9,"layer_index":3,"chromosome_index":2}],[{"genes":[8,3,6,0,11,1,6,2,9,9],"command_range":[0,1,2,3,4,5,6,8,9,11],"num_inputs":3,"layer_index":4,"chromosome_index":0},{"genes":[5,3,8,4,0,1,4,4,9,9],"command_range":[0,1,2,3,4,5,6,8,9,11],"num_inputs":3,"layer_index":4,"chromosome_index":1},{"genes":[0,5,1,3,8,5,3,5,6,9],"command_range":[0,1,2,3,4,5,6,8,9,11],"num_inputs":3,"layer_index":4,"chromosome_index":2}]]}
```

### 2. 11 000 fitness, 8 400 steps max (9 000 fitness, 6 500 steps average)

```json
{"dna":[[{"genes":[[4,1,3,-1,-2],[-4,-5,1,1,-1],[-2,2,-3,1,-3],[-2,-4,-5,-3,-4],[-1,1,1,-1,4]],"results_dimensions":{"height":7,"width":7},"random_range":{"from":-5,"to":5},"num_inputs":1,"layer_index":0,"chromosome_index":0},{"genes":[[1,1,-5,-1,-5],[-5,1,1,4,-5],[4,0,3,-5,1],[2,3,4,-5,-5],[3,4,3,-5,3]],"results_dimensions":{"height":7,"width":7},"random_range":{"from":-5,"to":5},"num_inputs":1,"layer_index":0,"chromosome_index":1},{"genes":[[0,5,-3,-1,3],[-5,-3,1,3,-3],[2,-2,-5,-2,-5],[-2,5,1,5,-5],[4,-4,4,2,-5]],"results_dimensions":{"height":7,"width":7},"random_range":{"from":-5,"to":5},"num_inputs":1,"layer_index":0,"chromosome_index":2}],[{"genes":[[-1,-3,-5],[5,-4,-3],[2,-4,3]],"results_dimensions":{"height":5,"width":5},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":1,"chromosome_index":0},{"genes":[[2,5,-1],[3,1,-1],[5,3,3]],"results_dimensions":{"height":5,"width":5},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":1,"chromosome_index":1},{"genes":[[5,4,-3],[2,4,-1],[5,-2,5]],"results_dimensions":{"height":5,"width":5},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":1,"chromosome_index":2}],[{"genes":[[4,-1,0],[3,1,4],[-1,-5,-5]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":0},{"genes":[[-5,2,0],[2,-4,1],[-4,4,3]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":1},{"genes":[[2,-2,-1],[1,2,1],[4,2,3]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":2},{"genes":[[5,1,0],[4,2,-2],[-1,2,-2]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":3},{"genes":[[5,4,5],[2,1,4],[3,5,-5]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":4},{"genes":[[-2,4,2],[-1,-1,-4],[-4,-4,4]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":5},{"genes":[[3,2,-2],[3,-2,-1],[-3,-1,1]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":6},{"genes":[[1,2,4],[5,-1,1],[5,5,-4]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":7},{"genes":[[0,-5,-1],[1,2,-2],[5,3,4]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":8}],[{"genes":[[-3],[-1],[-1]],"results_dimensions":{"height":3,"width":1},"random_range":{"from":-5,"to":5},"num_inputs":9,"layer_index":3,"chromosome_index":0},{"genes":[[1],[3],[1]],"results_dimensions":{"height":3,"width":1},"random_range":{"from":-5,"to":5},"num_inputs":9,"layer_index":3,"chromosome_index":1},{"genes":[[2],[0],[4]],"results_dimensions":{"height":3,"width":1},"random_range":{"from":-5,"to":5},"num_inputs":9,"layer_index":3,"chromosome_index":2}],[{"genes":[2,5,0,1,11,8,4,4,1,3],"command_range":[0,1,2,3,4,5,6,8,9,11],"num_inputs":3,"layer_index":4,"chromosome_index":0},{"genes":[5,2,9,6,0,2,9,3,9,4],"command_range":[0,1,2,3,4,5,6,8,9,11],"num_inputs":3,"layer_index":4,"chromosome_index":1},{"genes":[3,2,11,4,3,0,3,9,9,3],"command_range":[0,1,2,3,4,5,6,8,9,11],"num_inputs":3,"layer_index":4,"chromosome_index":2}]]}
```

### 3. 13 500 fitness, 8 500 steps max (9 000 fitness, 7 000 steps average)

```json
{"dna":[[{"genes":[[-3,-1,-1,2,-4],[1,5,5,-5,-3],[3,-1,-1,2,2],[-1,-2,-2,-4,0],[2,3,1,1,-2]],"results_dimensions":{"height":7,"width":7},"random_range":{"from":-5,"to":5},"num_inputs":1,"layer_index":0,"chromosome_index":0},{"genes":[[-3,-5,-4,-1,4],[-1,0,-4,5,5],[4,-4,5,4,3],[4,-5,4,3,-1],[-4,-3,4,-5,-1]],"results_dimensions":{"height":7,"width":7},"random_range":{"from":-5,"to":5},"num_inputs":1,"layer_index":0,"chromosome_index":1},{"genes":[[1,1,-5,3,2],[-2,4,-1,0,1],[1,-3,3,4,5],[0,-3,5,2,2],[-1,-1,-4,3,0]],"results_dimensions":{"height":7,"width":7},"random_range":{"from":-5,"to":5},"num_inputs":1,"layer_index":0,"chromosome_index":2}],[{"genes":[[-5,-4,-4],[-2,-4,2],[-3,-1,5]],"results_dimensions":{"height":5,"width":5},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":1,"chromosome_index":0},{"genes":[[-5,-4,-3],[-3,-3,-5],[-4,-1,2]],"results_dimensions":{"height":5,"width":5},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":1,"chromosome_index":1},{"genes":[[-1,0,4],[3,-4,-2],[1,-5,4]],"results_dimensions":{"height":5,"width":5},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":1,"chromosome_index":2}],[{"genes":[[3,2,3],[5,-5,3],[-2,3,3]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":0},{"genes":[[-3,-4,-3],[2,2,3],[0,2,-3]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":1},{"genes":[[1,0,-1],[-3,4,1],[-4,-2,-2]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":2},{"genes":[[3,5,-4],[3,-1,-4],[-3,5,-4]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":3},{"genes":[[2,-3,-3],[-2,2,-1],[-3,0,4]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":4},{"genes":[[3,-2,-5],[5,5,-5],[-2,1,-3]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":5},{"genes":[[4,2,-2],[5,1,-1],[1,-1,0]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":6},{"genes":[[3,-1,2],[-5,4,3],[5,5,5]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":7},{"genes":[[-4,-1,-4],[-5,-5,2],[-4,0,5]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":8}],[{"genes":[[-2],[4],[2]],"results_dimensions":{"height":3,"width":1},"random_range":{"from":-5,"to":5},"num_inputs":9,"layer_index":3,"chromosome_index":0},{"genes":[[3],[-4],[5]],"results_dimensions":{"height":3,"width":1},"random_range":{"from":-5,"to":5},"num_inputs":9,"layer_index":3,"chromosome_index":1},{"genes":[[-3],[-3],[-5]],"results_dimensions":{"height":3,"width":1},"random_range":{"from":-5,"to":5},"num_inputs":9,"layer_index":3,"chromosome_index":2}],[{"genes":[5,0,8,4,8,0,5,4,2,3],"command_range":[0,1,2,3,4,5,6,8,9,11],"num_inputs":3,"layer_index":4,"chromosome_index":0},{"genes":[9,3,3,2,4,5,8,8,4,9],"command_range":[0,1,2,3,4,5,6,8,9,11],"num_inputs":3,"layer_index":4,"chromosome_index":1},{"genes":[5,9,1,0,1,0,0,2,1,0],"command_range":[0,1,2,3,4,5,6,8,9,11],"num_inputs":3,"layer_index":4,"chromosome_index":2}]]}
```

### 4. 4 000 fitness, 4 000 steps max (3 000 fitness, 3 000 steps average)

```json
{"dna":[[{"genes":[[1,4,2,2,3],[3,-1,-1,2,2],[-4,1,1,5,-2],[2,5,2,0,2],[3,4,1,4,-3]],"results_dimensions":{"height":7,"width":7},"random_range":{"from":-5,"to":5},"num_inputs":1,"layer_index":0,"chromosome_index":0},{"genes":[[1,4,-3,-5,-4],[-2,-2,-5,-5,-2],[0,-4,-1,5,-4],[-1,0,-5,-4,3],[3,-1,-2,3,4]],"results_dimensions":{"height":7,"width":7},"random_range":{"from":-5,"to":5},"num_inputs":1,"layer_index":0,"chromosome_index":1},{"genes":[[-3,0,0,-3,3],[-4,-1,4,-5,4],[0,1,-3,2,-1],[3,5,1,-4,-2],[-4,4,-5,-3,0]],"results_dimensions":{"height":7,"width":7},"random_range":{"from":-5,"to":5},"num_inputs":1,"layer_index":0,"chromosome_index":2}],[{"genes":[[-2,1,-2],[1,-5,-3],[4,-4,2]],"results_dimensions":{"height":5,"width":5},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":1,"chromosome_index":0},{"genes":[[3,1,2],[-1,0,-4],[-1,3,-4]],"results_dimensions":{"height":5,"width":5},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":1,"chromosome_index":1},{"genes":[[-5,3,5],[-4,5,2],[-2,0,-4]],"results_dimensions":{"height":5,"width":5},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":1,"chromosome_index":2}],[{"genes":[[0,-2,-1],[3,4,-2],[0,-4,4]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":0},{"genes":[[2,-1,1],[2,4,1],[5,-4,0]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":1},{"genes":[[-3,3,2],[0,5,1],[-4,-1,-2]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":2},{"genes":[[-4,2,4],[-1,3,2],[0,1,-3]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":3},{"genes":[[-3,5,2],[1,2,-1],[-5,3,-4]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":4},{"genes":[[-2,5,-1],[1,3,-1],[3,-3,0]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":5},{"genes":[[-5,-3,-2],[-4,1,4],[-1,1,-2]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":6},{"genes":[[0,-4,-3],[-5,2,1],[-5,-3,2]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":7},{"genes":[[3,4,3],[-4,2,-1],[-4,1,3]],"results_dimensions":{"height":3,"width":3},"random_range":{"from":-5,"to":5},"num_inputs":3,"layer_index":2,"chromosome_index":8}],[{"genes":[[2],[2],[1]],"results_dimensions":{"height":3,"width":1},"random_range":{"from":-5,"to":5},"num_inputs":9,"layer_index":3,"chromosome_index":0},{"genes":[[2],[3],[0]],"results_dimensions":{"height":3,"width":1},"random_range":{"from":-5,"to":5},"num_inputs":9,"layer_index":3,"chromosome_index":1},{"genes":[[-5],[-2],[1]],"results_dimensions":{"height":3,"width":1},"random_range":{"from":-5,"to":5},"num_inputs":9,"layer_index":3,"chromosome_index":2}],[{"genes":[9,8,9,3,3,9,3,9,0,5],"command_range":[0,1,2,3,4,5,6,8,9,11],"num_inputs":3,"layer_index":4,"chromosome_index":0},{"genes":[4,4,3,0,5,0,0,11,3,6],"command_range":[0,1,2,3,4,5,6,8,9,11],"num_inputs":3,"layer_index":4,"chromosome_index":1},{"genes":[5,9,4,1,6,2,6,1,2,6],"command_range":[0,1,2,3,4,5,6,8,9,11],"num_inputs":3,"layer_index":4,"chromosome_index":2}]]}
```

## Conclusion

In result it means that the system can solve this problem in some way, also the genetic engine works quite well and can help in solving problems like this.

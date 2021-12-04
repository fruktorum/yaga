require "../../../src/yaga/chromosomes/matrix"
require "../../../src/yaga/chromosomes/equation"

module SnakeGenetic
  # Because of module wraps `Chromosome` subclasses, they need to explicitly define json initialization method.
  # Without this wrapper that contais only `super` call, compiler returns an error:
  # Error: wrong number of arguments for 'SnakeGenetic::Convolution#initialize' (given 1, expected 3)
  # Overloads are:
  #  - SnakeGenetic::Convolution#initialize(num_inputs, layer_index, chromosome_index)
  # This happens because of strong engine internal macros infrastructure and DNA compile-time definition
  # See https://github.com/crystal-lang/crystal/issues/3139 for reference

  class Convolution < YAGA::Chromosomes::Matrix(Int32, Array(SimpleMatrix(Int32)), SimpleMatrix(Int32))
    def initialize(pull : JSON::PullParser)
      super
    end

    def initialize(@num_inputs, @layer_index, @chromosome_index)
      @genes = SimpleMatrix(T).new 3, 3                                         # Kernel
      @results = SimpleMatrix(T).new 7 - @layer_index * 2, 7 - @layer_index * 2 # Convolution results per layer
      @random_range = -5..5
      randomize
    end

    def activate(inputs : U) : V
      inputs[@chromosome_index % inputs.size].convolve @genes, @results
      prepare_result
    end
  end

  class ConvolutionInput < Convolution
    def initialize(pull : JSON::PullParser)
      super
    end

    def initialize(@num_inputs, @layer_index, @chromosome_index)
      @genes = SimpleMatrix(T).new 5, 5   # Kernel
      @results = SimpleMatrix(T).new 7, 7 # Convolution result
      @random_range = -5..5
      randomize
    end
  end

  class DotMatrix < YAGA::Chromosomes::Matrix(Int32, Array(SimpleMatrix(Int32)), Array(Float64))
    def initialize(pull : JSON::PullParser)
      super
    end

    def initialize(@num_inputs, @layer_index, @chromosome_index)
      # Dot product with matrix 3x1 makes result matrix 3x1
      @genes = SimpleMatrix(T).new 3, 1
      @results = SimpleMatrix(T).new 3, 1
      @random_range = -5..5
      randomize
    end

    def activate(inputs : U) : V
      sum_inputs = SimpleMatrix(T).new inputs.first.height, inputs.first.width

      # Apply each multiplication to sum of 5 convolution results
      5.times { |index|
        input_index = @chromosome_index < 2 && index < 4 ? @chromosome_index * 3 + index : index - 4
        sum_inputs.sum inputs[input_index], sum_inputs
      }
      sum_inputs.dot @genes, @results

      @results.buffer.map { |row| row[0].to_f64 }
    end
  end

  class Equation < YAGA::Chromosomes::Equation
    def initialize(pull : JSON::PullParser)
      super
    end

    def initialize(num_inputs, layer_index, chromosome_index)
      super num_inputs, layer_index, chromosome_index, 10_u8, Array(UInt8){0, 1, 2, 3, 4, 5, 6, 8, 9, 11}
    end

    # Current: Y = f( sum_i inputs_i )
    # It can be patched to: Y = sum_i f( inputs_i )
    # but it works with the same quality
    def activate(inputs : Array(Array(Float64))) : Float64
      @tree.eval inputs[@chromosome_index].sum
    end
  end

  YAGA::Genome.compile(
    SnakeGenetic::DNA, Array(SimpleMatrix(Int32)), 1,

    {ConvolutionInput, Array(SimpleMatrix(Int32)), 3},
    {Convolution, Array(SimpleMatrix(Int32)), 3},
    {Convolution, Array(SimpleMatrix(Int32)), 9},
    {DotMatrix, Array(Array(Float64)), 3},
    {Equation, Array(Float64), 3}
  )
end

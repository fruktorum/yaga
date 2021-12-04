# T - internal genes class
# U - inputs class
# V - activation class

require "simple_matrix"

module YAGA
  module Chromosomes
    class Matrix(T, U, V)
      include Chromosome(SimpleMatrix(T), U, V)

      private macro prepare_result
        {% if V == T %}
          @results.buffer.first.first
        {% elsif V == Array(T) %}
          @results.buffer.first
        {% elsif V == Array(Array(T)) %}
          @results.buffer
        {% elsif V == SimpleMatrix(T) %}
          @results
          # Ignore `else` - this is an error case
        {% end %}
      end

      RANDOM_RANGE = -5_i8..5_i8

      @random_range : Range(T, T)
      @results : SimpleMatrix(T)

      def initialize(pull : JSON::PullParser)
        @genes = SimpleMatrix(T).new 0, 0

        @num_inputs = 0
        @layer_index = 0
        @chromosome_index = 0

        results_height = 0
        results_width = 0

        range_from = 0
        range_to = 0

        pull.read_object { |key|
          case key
          when "genes"            then @genes = SimpleMatrix(T).new pull
          when "num_inputs"       then @num_inputs = pull.read_int.to_u32
          when "layer_index"      then @layer_index = pull.read_int.to_u32
          when "chromosome_index" then @chromosome_index = pull.read_int.to_u32
          when "results_dimensions"
            pull.read_object { |dimensions|
              case dimensions
              when "height" then results_height = pull.read_int
              when "width"  then results_width = pull.read_int
              else               pull.skip
              end
            }
          when "random_range"
            pull.read_object { |range|
              case range
              when "from" then range_from = pull.read_float
              when "to"   then range_to = pull.read_float
              else             pull.skip
              end
            }
          else pull.skip
          end
        }

        @results = SimpleMatrix(T).new results_height, results_width
        @random_range = T.new(range_from)..T.new(range_to)
      end

      def initialize(@num_inputs, @layer_index, @chromosome_index, @random_range = T.new(RANDOM_RANGE.begin)..T.new(RANDOM_RANGE.end))
        @genes = SimpleMatrix(T).new @num_inputs, 1
        @results = SimpleMatrix(T).new 1, 1
        randomize
      end

      def activate(inputs : U) : V
        raise ArgumentError.new "Unsupported type: #{U.inspect}"
      end

      def activate(inputs : Array(SimpleMatrix(T))) : V
        inputs[@chromosome_index].dot @genes, @results
        prepare_result
      end

      def activate(inputs : Array(Array(T))) : V
        matrix_inputs = SimpleMatrix(T).new(inputs.size, inputs.first.size) { |y, x| inputs[y][x] }
        matrix_inputs.dot @genes, @results
        prepare_result
      end

      def activate(inputs : Array(T)) : V
        matrix_inputs = SimpleMatrix(T).new(1, inputs.size) { |y, x| inputs[x] }
        matrix_inputs.dot @genes, @results
        prepare_result
      end

      def activate(inputs : T) : V
        @genes.mul inputs, @results
        prepare_result
      end

      def randomize : Void
        @genes.apply(@genes) { @random.rand @random_range }
      end

      def mutate : Void
        @genes.buffer[@random.rand @genes.height][@random.rand @genes.width] = @random.rand @random_range
      end

      def replace(other : Chromosome) : Void
        other_buffer = other.genes.as(SimpleMatrix(T)).buffer
        @genes.apply(@genes) { |value, y, x| other_buffer[y][x] }
      end

      def crossover(other : Chromosome) : Void
        other_buffer = other.genes.as(SimpleMatrix(T)).buffer
        target_buffer = @genes.buffer

        @random.rand(@genes.height * @genes.width * 0.5).to_i.times {
          y, x = @random.rand(@genes.height), @random.rand(@genes.width)
          target_buffer[y][x] = other_buffer[y][x]
        }
      end

      def size : UInt64
        @genes.width.to_u64 * @genes.height.to_u64
      end

      def to_json(json : JSON::Builder) : Void
        json.object {
          json.field(:genes) { @genes.to_json json }

          json.field(:results_dimensions) {
            json.object {
              json.field(:height) { json.number @results.height }
              json.field(:width) { json.number @results.width }
            }
          }

          json.field(:random_range) {
            json.object {
              json.field(:from) { json.number @random_range.begin }
              json.field(:to) { json.number @random_range.end }
            }
          }

          super
        }
      end
    end
  end
end

module YAGA
  module EquationParser
    class Node
      @value : UInt8 | Symbol
      @children : Array(Node)
      @arity : UInt8
      @result : Float64?

      property value, arity, result
      getter children

      def initialize(@value, @arity)
        @children = Array(Node).new
      end
    end
  end
end

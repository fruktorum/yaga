require "./parser"
require "./node"

module YAGA

	module EquationParser

		class Tree
			@stack : Array( Node )

			def initialize( buffer : Array( UInt8 ) )
				@stack = Array( Node ).new
				@parser = Parser.new
				parse buffer
			end

			def eval( input : Float64 ) : Float64
				@stack.each{|node|
					node.result = case node.value
						when :neg  then neg( node.children[ 0 ]? )
						when :sum  then sum( node.children[ 0 ]?, node.children[ 1 ]? )
						when :mul  then mul( node.children[ 0 ]?, node.children[ 1 ]? )
						when :sin  then sin( node.children[ 0 ]? )
						when :cos  then cos( node.children[ 0 ]? )
						when :tan  then tan( node.children[ 0 ]? )
						when :lg2  then log( node.children[ 0 ]?, 2 )
						when :lg10 then log( node.children[ 0 ]?, 10 )
						when :lge  then log( node.children[ 0 ]?, Math::E )
						when :x    then input.to_f64
						when :pi   then Math::PI
						when :e    then Math::E
						when UInt8 then node.value.as( UInt8 ).to_f64
					end
				}

				@stack.last.result || 0_f64
			end

			def parse( buffer : Array( UInt8 ) ) : Void
				current_node = Node.new :none, 0_u8
				@parser.load buffer

				@stack.clear
				@stack << current_node

				pointer = 0

				while ( token = @parser.next )[ 0 ] != :none
					next if token[ 0 ] == :error

					if current_node.value != :none
						while current_node.arity == current_node.children.size
							pointer += 1
							current_node = @stack[ pointer ]
						end

						target_node = Node.new :none, 0_u8
						@stack << target_node
					else
						target_node = current_node
					end

					current_node.children << target_node if current_node != target_node

					case token[ 0 ]
						when :val
							target_node.value = token[ 3 ].as UInt8
							target_node.arity = 0_u8
						else
							target_node.value = token[ 0 ]
							target_node.arity = token[ 1 ]
					end
				end

				@stack.reverse!
			end

			private def neg( value : Node? ) : Float64?
				return unless value && ( result = value.result )
				-result
			end

			private def sum( value1 : Node?, value2 : Node? ) : Float64?
				return unless value1 || value2
				return value1.not_nil!.result unless value2 && ( result2 = value2.result )
				return value2.result unless value1 && ( result1 = value1.result )

				result1 + result2
			end

			private def mul( value1 : Node?, value2 : Node? ) : Float64?
				return unless value1 || value2
				return value1.not_nil!.result unless value2 && ( result2 = value2.result )
				return value2.result unless value1 && ( result1 = value1.result )

				result1 * result2
			end

			private def sin( value : Node? ) : Float64?
				return unless value && ( result = value.result )
				Math.sin result
			end

			private def cos( value : Node? ) : Float64?
				return unless value && ( result = value.result )
				Math.cos result
			end

			private def tan( value : Node? ) : Float64?
				return unless value && ( result = value.result )
				Math.tan result
			end

			private def log( value : Node?, basis : Number ) : Float64?
				return unless value && ( result = value.result )
				return if result <= 0 || basis < 0 || basis == 1
				Math.log result, basis
			end
		end

	end

end

require "./interface"
require "./snake"

module Game

	class Field
		enum Penalty : UInt16
			Wall = 50
			SelfTail = 25
			OtherTail = 25
			Exhaustion = 0
		end

		Interface = Game::Interface.new

		getter snakes

		delegate hide, show, to: Interface

		@width : UInt16
		@height : UInt16

		@snakes : Array( Snake )

		@food_amount : UInt16
		@food : Array( Array( Bool ) )

		def initialize( @width, @height, @food_amount )
			Interface.dimensions @width, @height

			@snakes = Array( Snake ).new
			@food = Array( Array( Bool ) ).new( @height ){ Array( Bool ).new @width, false }

			walls
		end

		def tick : Void
			@snakes.each{|snake|
				sensors = snake_sensors snake
				next unless clear_part = snake.move sensors

				Interface.empty *clear_part
				eat_food snake

				target = check_death snake
				manage_dead snake, target if target
			}

			render
			sleep 0.02 if Interface.visible
		end

		def render : Void
			@snakes.each{|snake|
				Interface.entity snake.x, snake.y, :purple
				snake.tail.each{ |x, y| Interface.entity x, y }
			}

			@food.each_with_index{ |row, y| row.each_with_index{ |value, x| Interface.food x.to_u16, y.to_u16 if value } }

			Interface.flush
		end

		def generate_food : Void
			x, y = rand( 1_u16 .. @width - 2 ), rand( 1_u16 .. @height - 2 )

			while check_snake( x, y ) || @food[ y ][ x ]
				x, y = rand( 1_u16 .. @width - 2 ), rand( 1_u16 .. @height - 2 )
			end

			@food[ y ][ x ] = true
		end

		def reset : Void
			@snakes.each &.reset
			@food.each &.fill( false )
			@food_amount.times{ generate_food }
			Interface.clear
		end

		private def walls : Void
			@height.times{|y|
				Interface.wall 0, y
				Interface.wall @width - 1, y
			}

			@width.times{|x|
				Interface.wall x, 0
				Interface.wall x, @height - 1
			}
		end

		private def eat_food( snake : Snake ) : Void
			if snake.y < @height && snake.x < @width && @food[ snake.y ][ snake.x ]
				@food[ snake.y ][ snake.x ] = false
				snake.add_food_bonus
				generate_food
			end
		end

		private def check_death( snake : Snake ) : Penalty?
			return Penalty::Exhaustion if snake.health == 0
			return Penalty::SelfTail if snake.tail.any?{ |x, y| snake.x == x && snake.y == y }
			return Penalty::Wall if snake.x == 0 || snake.y == 0 || snake.x == @width - 1 || snake.y == @height - 1

			@snakes.each{|other_snake|
				if other_snake != snake
					return Penalty::OtherTail if other_snake.x == snake.x && other_snake.y == snake.y
					return Penalty::OtherTail if other_snake.tail.any?{ |x, y| x == snake.x && y == snake.y }
				end
			}

			nil
		end

		private def manage_dead( snake : Snake, target : Penalty ) : Void
			case target
				when .wall? then Interface.empty snake.x, snake.y
				when .other_tail? then Interface.entity snake.x, snake.y
				when .exhaustion? then Interface.empty snake.x, snake.y
				when .self_tail? # Do nothing - tail will be cleared later
			end

			snake.tail.each{ |part| Interface.empty *part }

			bonus = ( snake.tail_size - Snake::BASE_TAIL_SIZE ) * 5 + snake.steps_alive
			penalty = Snake::BASE_HEALTH + target.value

			snake.fitness = penalty < bonus ? ( bonus - penalty ).to_u32 : 0_u32

			@snakes.delete snake
		end

		private def snake_sensors( snake : Snake ) : SimpleMatrix( Int32 )
			direction = snake.absolute_direction

			SimpleMatrix( Int32 ).new( 11, 11 ){|y, x|
				value = 0

				offset_y, offset_x = case direction
					when .up?    then { snake.y + y < 5 ? 0_u16 : snake.y + y - 5, snake.x + x < 5 ? 0_u16 : snake.x + x - 5 }
					when .down?  then { snake.y + 5 < y ? 0_u16 : snake.y + 5 - y, snake.x + 5 < x ? 0_u16 : snake.x + 5 - x }
					when .left?  then { snake.y + 5 < x ? 0_u16 : snake.y + 5 - x, snake.x + y < 5 ? 0_u16 : snake.x + y - 5 }
					when .right? then { snake.y + x < 5 ? 0_u16 : snake.y + x - 5, snake.x + 5 < y ? 0_u16 : snake.x + 5 - y }
					else raise Exception.new "Should not be here"
				end

				value = case
					when offset_y <= 0 || offset_x <= 0 || offset_y >= @height - 1 || offset_x >= @width - 1 then -1
					when @food[ offset_y ][ offset_x ] then 2
					when check_snake offset_x, offset_y then -2
					else 0
				end

				value
			}
		end

		private def check_snake( x : UInt16, y : UInt16 ) : Bool
			@snakes.any?{ |snake| snake.x == x && snake.y == y || snake.tail.any?{ |tail_x, tail_y| tail_x == x && tail_y == y } }
		end
	end

end

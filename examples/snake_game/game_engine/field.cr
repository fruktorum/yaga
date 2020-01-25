require "./interface"
require "./snake"

module Game

	class Field
		WALL_PENALTY = 50_u16
		TAIL_PENALTY = 25_u16
		BASE_PENALTY = 0_u16

		getter snakes

		delegate hide, show, visible, to: @interface

		@width : UInt16
		@height : UInt16

		@snakes : Array( Snake )

		@food_amount : UInt16
		@food : Array( Array( Bool ) )

		@interface : Interface( UInt16 )

		def initialize( @width, @height, @food_amount )
			@interface = Interface( UInt16 ).new @width, @height
			@snakes = Array( Snake ).new
			@food = Array( Array( Bool ) ).new( @height ){ Array( Bool ).new @width, false }
		end

		def tick : Void
			@snakes.each{|snake|
				sensors = snake_sensors snake
				next unless clear_part = snake.move sensors

				@interface.empty *clear_part
				eat_food snake

				death, target = check_death snake
				manage_dead snake, target.not_nil! if death
			}

			render
		end

		def render : Void
			@snakes.each{|snake|
				@interface.entity snake.x, snake.y, 45
				snake.tail.each{ |x, y| @interface.entity x, y }
			}

			@food.each_with_index{ |row, y| row.each_with_index{ |value, x| @interface.food x.to_u16, y.to_u16 if value } }

			@interface.flush
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
			pre_render
		end

		private def pre_render : Void
			@interface.clear

			@height.times{|y|
				@interface.wall 0, y
				@interface.wall @width - 1, y
			}

			@width.times{|x|
				@interface.wall x, 0
				@interface.wall x, @height - 1
			}
		end

		private def eat_food( snake : Snake ) : Void
			if snake.y < @height && snake.x < @width && @food[ snake.y ][ snake.x ]
				@food[ snake.y ][ snake.x ] = false
				snake.add_food_bonus
				generate_food
			end
		end

		private def check_death( snake : Snake ) : Tuple( Bool, Symbol? )
			return { true, :tail } if snake.health == 0
			return { true, :tail } if snake.tail.any?{ |x, y| snake.x == x && snake.y == y }
			return { true, :wall } if snake.x == 0 || snake.y == 0 || snake.x == @width - 1 || snake.y == @height - 1

			@snakes.each{|other_snake|
				if other_snake != snake
					return { true, :other_head } if other_snake.x == snake.x && other_snake.y == snake.y
					return { true, :other_tail } if other_snake.tail.any?{ |x, y| x == snake.x && y == snake.y }
				end
			}

			{ false, nil }
		end

		private def manage_dead( snake : Snake, target : Symbol ) : Void
			penalty = Snake::BASE_HEALTH + case target
				when :wall
					@interface.wall snake.x, snake.y
					WALL_PENALTY
				when :other_head then TAIL_PENALTY # Nothing to do - head is visually same
				when :other_tail
					@interface.entity snake.x, snake.y
					TAIL_PENALTY
				when :tail then TAIL_PENALTY # Optimization: tail clears later
				else
					@interface.empty snake.x, snake.y
					BASE_PENALTY
			end

			snake.tail.each{ |part| @interface.empty *part }

			bonus = snake.tail_size * 15 + snake.steps_alive
			snake.fitness = penalty < bonus ? ( bonus - penalty ).to_f64 : 0_f64

			@snakes.delete snake
		end

		private def snake_sensors( snake : Snake ) : SimpleMatrix( Int32 )
			direction = snake.absolute_direction

			SimpleMatrix( Int32 ).new( 11, 11 ){|y, x|
				value = 0

				offset_y, offset_x = case direction
					when :up    then { snake.y + y < 5 ? 0_u16 : snake.y + y - 5, snake.x + x < 5 ? 0_u16 : snake.x + x - 5 }
					when :down  then { snake.y + 5 < y ? 0_u16 : snake.y + 5 - y, snake.x + 5 < x ? 0_u16 : snake.x + 5 - x }
					when :left  then { snake.y + 5 < x ? 0_u16 : snake.y + 5 - x, snake.x + y < 5 ? 0_u16 : snake.x + y - 5 }
					when :right then { snake.y + x < 5 ? 0_u16 : snake.y + x - 5, snake.x + 5 < y ? 0_u16 : snake.x + 5 - y }
					else { 0_u16, 0_u16 }
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

module Game

	class Snake < YAGA::Bot( SnakeGenetic::DNA )
		BASE_HEALTH = 180_u16 # It is not needed to be a 16-bit but it allows more flexible customization

		getter x, y, tail, tail_size, absolute_direction, health, steps_alive

		@start_x : UInt16
		@start_y : UInt16

		@x : UInt16
		@y : UInt16

		@tail : Array( Tuple( UInt16, UInt16 ) )
		@tail_size : UInt16

		@absolute_direction : Symbol

		@health : UInt16
		@steps_alive : UInt32

		def initialize( @x, @y )
			@start_x = @x
			@start_y = @y

			@tail = Array( Tuple( UInt16, UInt16 ) ).new
			@tail_size = 0
			@absolute_direction = :up

			@health = 0
			@steps_alive = 0

			reset

			super()
		end

		def move( sensors : SimpleMatrix( Int32 ) ) : Tuple( UInt16, UInt16 )?
			@tail << { @x, @y }

			activations = activate [ sensors ]
			current_direction = %i[ forward left right ].zip( activations ).max_by{ |direction, activation| activation }[ 0 ]

			step current_direction
			@health -= 1
			@steps_alive += 1

			@tail.shift if @tail.size > @tail_size
		end

		def add_food_bonus : Void
			@health = BASE_HEALTH
			@tail.unshift @tail.first
			@tail_size += 1
		end

		def step( direction : Symbol ) : Void
			case direction
				when :forward
					case @absolute_direction
						when :up then @y -= 1 if @y > 0
						when :down then @y += 1
						when :left then @x -= 1 if @x > 0
						when :right then @x += 1
						else raise ArgumentError.new "Wrong absolute direction: '#{ @absolute_direction }'"
					end
				when :left
					case @absolute_direction
						when :up
							@x -= 1 if @x > 0
							@absolute_direction = :left
						when :down
							@x += 1
							@absolute_direction = :right
						when :left
							@y += 1
							@absolute_direction = :down
						when :right
							@y -= 1 if @y > 0
							@absolute_direction = :up
						else raise ArgumentError.new "Wrong absolute direction: '#{ @absolute_direction }'"
					end
				when :right
					case @absolute_direction
						when :up
							@x += 1 if @x > 0
							@absolute_direction = :right
						when :down
							@x -= 1
							@absolute_direction = :left
						when :left
							@y -= 1
							@absolute_direction = :up
						when :right
							@y += 1 if @y > 0
							@absolute_direction = :down
						else raise ArgumentError.new "Wrong absolute direction: '#{ @absolute_direction }'"
					end
				else raise ArgumentError.new "Wrong direction: '#{ direction }'"
			end
		end

		def reset : Void
			@x = @start_x
			@y = @start_y

			@tail.clear

			@tail << { @x, @y + 1 }
			@tail_size = @tail.size.to_u16

			@health = BASE_HEALTH
			@steps_alive = 0

			@absolute_direction = :up
		end
	end

end

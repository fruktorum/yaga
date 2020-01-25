module Game

	class Interface( T )
		getter visible

		@width : T
		@height : T
		@visible : Bool = true

		@buffer : String

		def initialize( @width, @height )
			@buffer = ""
		end

		def empty( x : T, y : T ) : Void
			print_subject "\e[0m ", x, y if @visible
		end

		def wall( x : T, y : T ) : Void
			print_subject "\e[47;1m \e[0m", x, y if @visible
		end

		def food( x : T, y : T ) : Void
			print_subject "\e[42m \e[0m", x, y if @visible
		end

		def entity( x : T, y : T, color : UInt8 = 46 ) : Void
			print_subject "\e[#{ color }m \e[0m", x, y if @visible
		end

		def clear : Void
			puts "\e[H\e[J\e[3J" if @visible
			@buffer = ""
		end

		def line : Void
			if @visible
				move @width, @height
				@buffer += "\n"
			end
		end

		def hide : Void
			@visible = false
		end

		def show : Void
			@visible = true
		end

		def flush : Void
			print @buffer
			@buffer = ""
		end

		private def print_subject( body : String, x : T, y : T ) : Void
			move x, y
			@buffer += body
			line
		end

		private def move( x : T, y : T ) : Void
			@buffer += "\x1b[#{ y + 1 };#{ x + 1 }H"
		end
	end

end

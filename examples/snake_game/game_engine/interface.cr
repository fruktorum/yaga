require "tilerender"
require "tilerender/interfaces/command_line"

module Game

	class Interface < Tilerender::CommandLine
		def wall( x : UInt16, y : UInt16 ) : Void
			background x, y, :white
		end

		def food( x : UInt16, y : UInt16 ) : Void
			foreground x, y, :green
		end

		def entity( x : UInt16, y : UInt16, color : Tilerender::Color = :teal ) : Void
			foreground x, y, color
		end
	end

end

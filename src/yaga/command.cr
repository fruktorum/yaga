# T - internal weights class
# U - activation class

module YAGA

	abstract class Command( T, U )
		getter weights

		@weights : T

		def initialize( inputs : Int32 )
			@weights = T.new inputs
			randomize
		end

		abstract def activate( inputs : T ) : U

		abstract def randomize : Void
		abstract def mutate : Void
		abstract def replace( other : Command ) : Void

		abstract def size : UInt64
		abstract def same?( other : Command ) : Bool
	end

end

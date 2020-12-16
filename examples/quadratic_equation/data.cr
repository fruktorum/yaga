class Data
	getter inputs, outputs

	@inputs : Array( UInt16 )
	@outputs : Array( Int64 )

	def initialize( @inputs, @outputs )
	end


	def self.f( x : UInt16 ) : Int64 # y = f(x)
		x.to_i64 ** 2_i64 - 5_i64 * x.to_i64 + 2_i64
	end
end

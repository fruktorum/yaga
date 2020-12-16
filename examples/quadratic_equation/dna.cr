class QuadraticEquation < YAGA::Chromosomes::Equation
	# Reduce chromosome size from defaults to 15
	# And use only specific functions parts: Neg, Sum, Mul, Const(1), Const(2), x
	def initialize( @num_inputs, @layer_index, @chromosome_index )
		super @num_inputs, @layer_index, @chromosome_index, 15_u8, Array( UInt8 ){ 0, 1, 2, 3, 4, 5 }
	end

	# Instead of floats, use UInt16 as inputs and Int64 for outputs (output can be really huge)
	def activate( inputs : Array( UInt16 ) ) : Int64
		@tree.eval( inputs[ 0 ].to_f64 ).to_i64
	end
end

YAGA::Genome.compile(
	# Generated genome class  Inputs type (array)       Inputs size
	QuadraticGenome         , Array( UInt16 )         , 1          ,

	# Activator               Activations type (array)  Outputs size
	{ QuadraticEquation     , Array( Int64 )          , 1            }
)

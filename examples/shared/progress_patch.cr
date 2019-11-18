require "progress"

class ProgressBar
	private def print( percent )
		position = ( ( @current.to_f * @width.to_f ) / @total ).to_i

		@output_stream.flush
		@output_stream.print "[#{ @complete * position }#{ @incomplete * ( @width - position ) }]  #{ percent } % (#{ @current.to_u64 } / #{ @total }) \r"
		@output_stream.flush
		@output_stream.print "\n" if done?
	end
end

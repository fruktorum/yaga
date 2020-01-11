module YAGA

	module EquationParser

		class Parser
			@buffer : Array( UInt8 )
			@pointer : UInt8
			@observer : UInt8

			getter pointer, observer

			def initialize
				@buffer = Array( UInt8 ).new
				@pointer = 0
				@observer = 1
			end

			def load( data : Array( UInt8 ) )
				@buffer.replace data
				@pointer = 0
				@observer = 1
			end

			def next : Tuple( Symbol, UInt8, UInt8?, UInt8? )
				subject = @buffer[ @pointer ]?

				return { :none, 0_u8, nil, nil } unless subject
				return { :none, 0_u8, nil, nil } if @observer <= @pointer

				@pointer += 1

				case subject
					when 0
						@observer += 1
						{ :neg, 1_u8, @buffer[ @observer ]?, nil }
					when 1
						@observer += 2
						{ :sum, 2_u8, @buffer[ @observer - 2 ]?, @buffer[ @observer - 1 ]? }
					when 2
						@observer += 2
						{ :mul, 2_u8, @buffer[ @observer - 2 ]?, @buffer[ @observer - 1 ]? }
					when 3 then { :val, 0_u8, nil, 1_u8 }
					when 4 then { :val, 0_u8, nil, 2_u8 }
					when 5 then { :x, 0_u8, nil, nil }
					when 6 then { :pi, 0_u8, nil, nil }
					when 7 then { :e, 0_u8, nil, nil }
					when 8
						@observer += 1
						{ :sin, 1_u8, @buffer[ @observer ]?, nil }
					when 9
						@observer += 1
						{ :cos, 1_u8, @buffer[ @observer ]?, nil }
					when 10
						@observer += 1
						{ :tan, 1_u8, @buffer[ @observer ]?, nil }
					when 11
						@observer += 1
						{ :lg2, 1_u8, @buffer[ @observer ]?, nil }
					when 12
						@observer += 1
						{ :lg10, 1_u8, @buffer[ @observer ]?, nil }
					when 13
						@observer += 1
						{ :lge, 1_u8, @buffer[ @observer ]?, nil }
					else { :error, 0_u8, nil, nil }
				end
			end
		end

	end

end

require "./command"

module YAGA

	abstract class Genome( T, U )
		MUTATION_SIZE = 2_u8
		MUTATION_COMMANDS = 2_u8

		CROSSOVER_SIZE = 3_u8

		macro compile( name, inputs_type, inputs_size, *layers )
			class {{ name }} < YAGA::Genome( {{ inputs_type }}, {{ layers.last[ 1 ] }} )
				alias GenesUnion = {% for layer, index in layers %} {{ layer[ 0 ] }} {% if index < layers.size - 1 %} | {% end %} {% end %}
				alias LayersUnion = {% for layer in layers %} {{ layer[ 1 ] }} | {% end %} {{ inputs_type }}

				@genes : Array( Array( GenesUnion ) )
				@layers : Array( LayersUnion )

				def initialize
					@genes = Array( Array( GenesUnion ) ).new
					@layers = Array( LayersUnion ).new

					{% for layer, index in layers %}
						@genes << Array( {{ layer[ 0 ] }} ).new( {{ layer[ 2 ] }} ){ {{ layer[ 0 ] }}.new {{ index == 0 ? inputs_size : layers[ index - 1 ][ 2 ] }}.to_i }
					{% end %}

					@layers << {{ inputs_type }}.new( {{ inputs_size }}.to_i )

					{% for layer, index in layers %}
						@layers << {{ layer[ 1 ] }}.new( {{ layer[ 2 ] }}.to_i )
					{% end %}

					super
				end

				def activate( inputs : {{ inputs_type }} ) : {{ layers.last[ 1 ] }}
					inputs.each_with_index{ |value, input_index| @layers[ 0 ][ input_index ] = value }

					@genes.each_with_index{|gene, index|
						input = @layers[ index ]
						activation = @layers[ index + 1 ]

						gene.each_with_index{|command, command_index| activation[ command_index ] = command.activate input }
					}

					@layers.last
				end
			end
		end

		getter genes

		abstract def activate( inputs : T ) : U

		def initialize
			generate
		end

		def generate : Void
			@genes.each{ |gene| gene.each &.randomize }
		end

		def replace( other : Genome( T, U ) ) : Void
			source_genes = other.genes
			@genes.each_with_index{ |gene, gene_index| gene.each_with_index{ |command, command_index| command.replace source_genes[ gene_index ][ command_index ] } }
		end

		def mutate : Void
			rand( 1_u8 .. MUTATION_SIZE ).times{
				gene = @genes[ rand @genes.size ]
				gene[ rand gene.size ].tap{ |command| MUTATION_COMMANDS.times{ command.mutate } }
			}
		end

		def crossover( other : Genome( T, U ) ) : Void
			other_genes = other.genes

			CROSSOVER_SIZE.times{
				crossing_gene_index = rand @genes.size

				source_gene = other_genes[ crossing_gene_index ]
				target_gene = @genes[ crossing_gene_index ]

				gene_index = rand target_gene.size

				source_command = source_gene[ gene_index ]
				target_command = target_gene[ gene_index ]

				target_command.replace source_command
			}
		end

		def size : UInt64
			result = 0_u64
			@genes.each &.each{ |command| result += command.size }
			result
		end

		def same?( other : Genome ) : Bool
			other_genes = other.genes
			@genes.each_with_index{ |gene, gene_index| gene.each_with_index{ |command, command_index| return false unless command.same?( other_genes[ gene_index ][ command_index ] ) } }
			true
		end
	end

end

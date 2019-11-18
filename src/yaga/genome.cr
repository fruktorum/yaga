require "./command"

module YAGA

	class Genome( T )
		MUTATION_SIZE = 2_u8
		MUTATION_COMMANDS = 2_u8

		CROSSOVER_SIZE = 3_u8

		alias Layer = Array( Command )

		getter genes

		@genes : Array( Layer )

		def initialize( architecture : Array( UInt16 ) )
			@genes = Array( Layer ).new
			( architecture.size - 1 ).times{ |index| @genes << Array( T ).new( architecture[ index + 1 ] ){ T.new architecture[ index ].to_i } }
			generate
		end

		def generate : Void
			@genes.each{ |layer| layer.each &.randomize }
		end

		def replace( other : Genome ) : Void
			source_genes = other.genes
			@genes.each_with_index{ |layer, layer_index| layer.each_with_index{ |command, command_index| command.replace source_genes[ layer_index ][ command_index ] } }
		end

		def mutate : Void
			rand( 1_u8 .. MUTATION_SIZE ).times{
				layer = @genes[ rand @genes.size ]
				layer[ rand layer.size ].tap{ |command| MUTATION_COMMANDS.times{ command.mutate } }
			}
		end

		def crossover( other : Genome ) : Void
			other_genes = other.genes

			CROSSOVER_SIZE.times{
				crossing_gene_index = rand @genes.size

				source_gene = other_genes[ crossing_gene_index ]
				target_gene = @genes[ crossing_gene_index ]

				layer_index = rand target_gene.size

				source_command = source_gene[ layer_index ]
				target_command = target_gene[ layer_index ]

				target_command.replace source_command
			}
		end

		def size : UInt64
			result = 0_u64
			@genes.each{ |layer| layer.each{ |command| result += command.size } }
			result
		end

		def same?( other : Genome ) : Bool
			other_genes = other.genes
			@genes.each_with_index{ |layer, layer_index| layer.each_with_index{ |command, command_index| return false unless command.same?( other_genes[ layer_index ][ command_index ] ) } }
			true
		end
	end

end

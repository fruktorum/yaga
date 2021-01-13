require "./chromosome"

module YAGA

	abstract class Genome( T, U )
		macro compile( name, inputs_type, inputs_size, *layers )
			class {{ name }} < ::YAGA::Genome( {{ inputs_type }}, {{ layers.last[ 1 ] }} )
				alias ChromosomesUnion = {% for layer, index in layers %} StaticArray( {{ layer[ 0 ] }}, {{ layer[ 2 ] }} ) {% if index < layers.size - 1 %} | {% end %} {% end %}
				alias LayersUnion = {% for layer in layers %} {{ layer[ 1 ] }} | {% end %} {{ inputs_type }}

				# At least 1 chromosome and at most 8 chromosomes should be crossovered
				# depending on the total chromosomes quantity in the DNA
				CROSSOVER_CHROMOSOMES_COUNT = {% result = 0 %} {% for layer in layers %} {% result += layer[ 2 ] %} {% end %} {% result //= 2 %} {{ result > 8 ? 8 : result == 0 ? 1 : result }}_u8

				# At least 1 layer and at most 2 layers should be mutated
				# depending on the total layers quantity in the DNA
				MUTATION_LAYERS_RANGE = 1_u8 .. {{ layers.size > 1 ? 2 : 1 }}_u8

				# At least 1 chromosome and at most 4 chromosomes should be mutated
				# depending on the total chromosomes quantity in the DNA
				MUTATION_CHROMOSOMES_COUNT = {% result = 0 %} {% for layer in layers %} {% result += layer[ 2 ] %} {% end %} {% result //= 4 %} {{ result > 4 ? 4 : result == 0 ? 1 : result }}_u8

				@dna : StaticArray( ChromosomesUnion, {{ layers.size }} )
				@activation_layers : StaticArray( LayersUnion, {{ layers.size + 1 }} )

				def initialize( pull : JSON::PullParser )
					@dna = uninitialized( {{ name }}::ChromosomesUnion )[ {{ layers.size }} ]

					{% for layer, index in layers %}
						@dna[ {{ index }} ] = StaticArray( {{ layer[ 0 ] }}, {{ layer[ 2 ] }} ).new{ |index| {{ layer[ 0 ] }}.new {{ index == 0 ? inputs_size : layers[ index - 1 ][ 2 ] }}_u32, {{ index }}_u32, index.to_u32 }
					{% end %}

					pull.on_key( "dna" ){
						pull.read_begin_array

						{% for layer, index in layers %}
							pull.read_begin_array
							@dna[ {{ index }} ] = StaticArray( {{ layer[ 0 ] }}, {{ layer[ 2 ] }} ).new{ |index| {{ layer[ 0 ] }}.new pull }
							pull.read_end_array
						{% end %}

						pull.read_end_array
					}

					@activation_layers = uninitialized( LayersUnion )[ {{ layers.size + 1 }} ]

					@activation_layers[ 0 ] = {% if inputs_type.resolve == Nil %}nil{% else %}{{ inputs_type }}.new {{ inputs_size }}.to_i{% end %}
					{% for layer, index in layers %}
						@activation_layers[ {{ index + 1 }} ] = {% if layer[ 1 ].resolve == Nil %}nil{% else %}{{ layer[ 1 ] }}.new {{ layer[ 2 ] }}.to_i{% end %}
					{% end %}
				end

				def initialize
					@dna = uninitialized( ChromosomesUnion )[ {{ layers.size }} ]
					@activation_layers = uninitialized( LayersUnion )[ {{ layers.size + 1 }} ]

					{% for layer, index in layers %}
						@dna[ {{ index }} ] = StaticArray( {{ layer[ 0 ] }}, {{ layer[ 2 ] }} ).new{ |index| {{ layer[ 0 ] }}.new( {{ index == 0 ? inputs_size : layers[ index - 1 ][ 2 ] }}_u32, {{ index }}_u32, index.to_u32 ) }
					{% end %}

					@activation_layers[ 0 ] = {% if inputs_type.resolve == Nil %}nil{% else %}{{ inputs_type }}.new {{ inputs_size }}.to_i{% end %}

					{% for layer, index in layers %}
						@activation_layers[ {{ index + 1 }} ] = {% if layer[ 1 ].resolve == Nil %}nil{% else %}{{ layer[ 1 ] }}.new( {{ layer[ 2 ] }}.to_i ){% end %}
					{% end %}

					super
				end

				def activate( inputs : {{ inputs_type }} ) : {{ layers.last[ 1 ] }}
					{% if inputs_type.resolve != Nil %}
						inputs.each_with_index{|value, input_index|
							layer = @activation_layers[ 0 ].as {{ inputs_type }}

							if layer[ input_index ]?.nil?
								layer << value if layer.responds_to? :<<
							else
								layer[ input_index ] = value
							end
						}
					{% end %}

					{% for layer, index in layers %}
						chromosomes = @dna[ {{ index }} ].as StaticArray( {{ layer[ 0 ] }}, {{ layer[ 2 ] }} )
						input = @activation_layers[ {{ index }} ].as {{ index == 0 ? inputs_type : layers[ index - 1 ][ 1 ] }}
						activation = @activation_layers[ {{ index + 1 }} ].as {{ layer[ 1 ] }}

						chromosomes.each_with_index{|chromosome, chromosome_index|
							activated_chromosome = chromosome.activate input
							if activation[ chromosome_index ]?.nil?
								activation << activated_chromosome if activation.responds_to? :<<
							else
								activation[ chromosome_index ] = activated_chromosome
							end
						}
					{% end %}

					@activation_layers.last.as {{ layers.last[ 1 ] }}
				end
			end
		end

		getter dna

		@random : Random = Random.new

		abstract def activate( inputs : T ) : U

		def initialize
			generate
		end

		def update_random( @random : Random ) : Void
			@dna.each &.each( &.update_random @random )
		end

		def generate : Void
			@dna.each &.each( &.randomize )
		end

		def replace( other : Genome( T, U ) ) : Void
			source_dna = other.dna
			@dna.each_with_index{ |chromosomes, chromosomes_layer_index| chromosomes.each_with_index{ |chromosome, chromosome_index| chromosome.replace source_dna[ chromosomes_layer_index ][ chromosome_index ] } }
		end

		def mutate : Void
			@random.rand( {{ @type.id + "::MUTATION_LAYERS_RANGE" }} ).times{
				chromosomes = @dna.sample @random
				chromosome = chromosomes.sample @random
				{{ @type.id + "::CROSSOVER_CHROMOSOMES_COUNT" }}.times{ chromosome.mutate }
			}
		end

		def crossover( other : Genome( T, U ) ) : Void
			other_dna = other.dna

			{{ @type.id + "::CROSSOVER_CHROMOSOMES_COUNT" }}.times{
				crossing_layer_index = @random.rand @dna.size

				source_chromosomes = other_dna[ crossing_layer_index ]
				target_chromosomes = @dna[ crossing_layer_index ]

				chromosome_index = @random.rand target_chromosomes.size

				source_chromosome = source_chromosomes[ chromosome_index ]
				target_chromosome = target_chromosomes[ chromosome_index ]

				target_chromosome.crossover source_chromosome
			}
		end

		def size : UInt64
			result = 0_u64
			@dna.each &.each{ |chromosome| result += chromosome.size }
			result
		end

		def same?( other : Genome ) : Bool
			other_dna = other.dna
			@dna.each_with_index{ |chromosomes, chromosomes_layer_index| chromosomes.each_with_index{ |chromosome, chromosome_index| return false unless chromosome.same? other_dna[ chromosomes_layer_index ][ chromosome_index ] } }
			true
		end

		def to_json( json : JSON::Builder ) : Void
			json.object{ json.field( :dna ){ json.array{ @dna.each{ |layer| json.array{ layer.each{ |chromosome| chromosome.to_json json } } } } } }
		end
	end

end

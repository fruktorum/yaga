require "big"
require "../../src/yaga"

require "./params_chromosome"
require "./train"

YAGA::Genome.compile(
  DerivativeEquation, Array(Int64), 1,
  {ParamsChromosome, Array(BigFloat), 1}
)

population = YAGA::Population(DerivativeEquation, Float64).new 8192, 64, 100

p :started

train population, 150000
best = population.selection.first

puts best.to_json

p zero_d1: best.genome.dna.first.first.activate_derivative(0_i64, 0)
p one_d1: best.genome.dna.first.first.activate_derivative(1_i64, 0)

p zero_d2: best.genome.dna.first.first.activate_derivative(0_i64, 1)
p one_d2: best.genome.dna.first.first.activate_derivative(1_i64, 1)

p zero_d3: best.genome.dna.first.first.activate_derivative(0_i64, 2)
p one_d3: best.genome.dna.first.first.activate_derivative(1_i64, 2)

p middle: best.genome.dna.first.first.evaluate(0.5)

require "./spec_helper"

module YAGA
  class Population(T, V)
    def _prepare_selection(bot : YAGA::Bot(T, V)) : Void
      prepare_selection bot
    end
  end
end

YAGA::Genome.compile(
  TestDNA, Array(UInt8), 1,
  {TestGenome, Array(UInt8), 1}
)

describe YAGA::Population do
  context "#prepare_selection" do
    it "does not change last selection bot" do
      population = YAGA::Population(TestDNA, Int32).new 16_u32, 4_u32
      population.train_world(100, 1) { |bots| bots.each_with_index { |bot, index| bot.fitness = index } }
      bot = YAGA::Bot(TestDNA, Int32).new
      bot.replace population.selection[-1]

      population.bots.reverse.each_with_index { |bot, index| bot.fitness = index + population.total_bots + 2 }
      population._prepare_selection bot

      bot.should be(population.selection[-1])
    end
  end
end

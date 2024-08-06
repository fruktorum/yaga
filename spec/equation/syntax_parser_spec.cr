require "../spec_helper"
require "../../src/yaga/chromosomes/equation_parser/tree"

describe YAGA::EquationParser::Tree do
  context "when initializes" do
    it "evals 0 (no function)" do
      tree = YAGA::EquationParser::Tree.new [0, 1, 2] of UInt8
      tree.eval(4).should eq(0)
    end

    it "evals 2 (y = constant)" do
      tree = YAGA::EquationParser::Tree.new [1, 0, 4] of UInt8
      tree.eval(4).should eq(2)
    end

    it "evals 1 (y = constant)" do
      tree = YAGA::EquationParser::Tree.new [3] of UInt8
      tree.eval(4).should eq(1)
    end

    it "evals 4 (y = x)" do
      tree = YAGA::EquationParser::Tree.new [5] of UInt8
      tree.eval(4).should eq(4)
    end

    it "evals -2 (y = negative constant)" do
      tree = YAGA::EquationParser::Tree.new [0, 1, 4] of UInt8
      tree.eval(4).should eq(-2)
    end

    it "evals -2 (y = negative constant)" do
      tree = YAGA::EquationParser::Tree.new [0, 4] of UInt8
      tree.eval(4).should eq(-2)
    end

    it "evals 128 (y = 2x^2)" do
      tree = YAGA::EquationParser::Tree.new [2, 2, 5, 1, 4, 5] of UInt8
      tree.eval(8).should eq(128)
    end

    it "evals 4 (y = 2 + (? + 2))" do
      tree = YAGA::EquationParser::Tree.new [1, 4, 1, 99, 4] of UInt8
      tree.eval(4).should eq(4)
    end

    it "evals 2 (y = 2 + (? + ?))" do
      tree = YAGA::EquationParser::Tree.new [1, 4, 1, 99, 99] of UInt8
      tree.eval(4).should eq(2)
    end

    it "evals 0.5 (y = 1/2)" do
      tree = YAGA::EquationParser::Tree.new [16, 1, 5, 5] of UInt8
      tree.eval(1).should eq(0.5)
    end

    it "evals 0 (y = 1/0)" do
      tree = YAGA::EquationParser::Tree.new [16, 5] of UInt8
      tree.eval(0).should eq(0)
    end

    it "evals 0 (y = 0^2)" do
      tree = YAGA::EquationParser::Tree.new [17, 5, 4] of UInt8
      tree.eval(0).should eq(0)
    end

    it "evals 1 (y = 2^0)" do
      tree = YAGA::EquationParser::Tree.new [17, 4, 5] of UInt8
      tree.eval(0).should eq(1)
    end

    it "evals 64 (y = 4^3)" do
      tree = YAGA::EquationParser::Tree.new [17, 1, 5, 4, 4] of UInt8
      tree.eval(3).should eq(64)
    end

    it "evals 1 (y = 1 + 1000000^1000000)" do
      tree = YAGA::EquationParser::Tree.new [1, 3, 17, 5, 5] of UInt8
      tree.eval(1000000).should eq(1)
    end

    it "evals 1 (1000000^???)" do
      tree = YAGA::EquationParser::Tree.new [17, 17, 17, 5, 5, 5, 5] of UInt8
      tree.eval(1000000).should eq(1)
    end

    it "equals after several operaitons" do
      tree = YAGA::EquationParser::Tree.new [2, 2, 5, 1, 4, 5] of UInt8
      tree.eval(8).should eq(128)
      tree.eval(8).should eq(128)
      tree.eval(4).should eq(32)
      tree.eval(4).should eq(32)
    end

    it "does not raise IndexError with small gene" do
      tree = YAGA::EquationParser::Tree.new [5, 4] of UInt8
      tree.eval(4).should eq(4)
    end
  end
end

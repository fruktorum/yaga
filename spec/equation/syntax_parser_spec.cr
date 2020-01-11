require "../spec_helper"
require "../../src/yaga/chromosomes/equation_parser/tree"

describe YAGA::EquationParser::Tree do
	context "when initializes" do
		it "evals 0 (no function)" do
			tree = YAGA::EquationParser::Tree.new [ 0, 1, 2 ] of UInt8
			tree.eval( 4 ).should eq( 0 )
		end

		it "evals 2 (y = constant)" do
			tree = YAGA::EquationParser::Tree.new [ 1, 0, 4 ] of UInt8
			tree.eval( 4 ).should eq( 2 )
		end

		it "evals 1 (y = constant)" do
			tree = YAGA::EquationParser::Tree.new [ 3 ] of UInt8
			tree.eval( 4 ).should eq( 1 )
		end

		it "evals 4 (y = x)" do
			tree = YAGA::EquationParser::Tree.new [ 5 ] of UInt8
			tree.eval( 4 ).should eq( 4 )
		end

		it "evals -2 (y = negative constant)" do
			tree = YAGA::EquationParser::Tree.new [ 0, 1, 4 ] of UInt8
			tree.eval( 4 ).should eq( -2 )
		end

		it "evals -2 (y = negative constant)" do
			tree = YAGA::EquationParser::Tree.new [ 0, 4 ] of UInt8
			tree.eval( 4 ).should eq( -2 )
		end

		it "evals 128 (y = 2x^2)" do
			tree = YAGA::EquationParser::Tree.new [ 2, 2, 5, 1, 4, 5 ] of UInt8
			tree.eval( 8 ).should eq( 128 )
		end

		it "evals 4 (y = 2 + (? + 2))" do
			tree = YAGA::EquationParser::Tree.new [ 1, 4, 1, 99, 4 ] of UInt8
			tree.eval( 4 ).should eq( 4 )
		end

		it "evals 2 (y = 2 + (? + ?))" do
			tree = YAGA::EquationParser::Tree.new [ 1, 4, 1, 99, 99 ] of UInt8
			tree.eval( 4 ).should eq( 2 )
		end

		it "equals after several operaitons" do
			tree = YAGA::EquationParser::Tree.new [ 2, 2, 5, 1, 4, 5 ] of UInt8
			tree.eval( 8 ).should eq( 128 )
			tree.eval( 8 ).should eq( 128 )
			tree.eval( 4 ).should eq( 32 )
			tree.eval( 4 ).should eq( 32 )
		end

		it "does not raise IndexError with small gene" do
			tree = YAGA::EquationParser::Tree.new [ 5, 4 ] of UInt8
			tree.eval( 4 ).should eq( 4 )
		end

		it "does not raise IndexError with large gene" do
			tree = YAGA::EquationParser::Tree.new [ 0, 2, 1, 2, 2, 0, 1, 1, 5, 4 ] of UInt8
			tree.eval( 3 ).should eq( -6 )
		end
	end
end

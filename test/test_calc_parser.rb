require 'minitest/autorun'
require_relative '../main'
require_relative '../sample/calc_lex'

class TestCalcParser < Minitest::Test
  def setup
    @calc2_grammer = Grammer.new(
      vn: Set[:S, :expr, :primary],
      vt: Set["(", ")", "*", "+", "-", "/", "^", "i", :EOF],
      s: :S,
      p: Set[
        Rule.new(:S,    [:expr],              -> v { v[0] }),
        Rule.new(:expr, [:expr, "+", :expr],  -> v { v[0] + v[2] }),
        Rule.new(:expr, [:expr, "/", :expr],  -> v { v[0] / v[2] }),
        Rule.new(:expr, [:expr, "*", :expr],  -> v { v[0] * v[2]}),
        Rule.new(:expr, [:expr, "-", :expr],  -> v { v[0] - v[2]}),
        Rule.new(:expr, [:expr, "^", :expr],  -> v { v[0] ** v[2]}),
        Rule.new(:expr, [:primary],           -> v { v[0] }),
        Rule.new(:primary, ["i"], -> v { v[0] }),
        Rule.new(:primary, ["(", :expr, ")"], -> v { v[1] }),
      ],
      precedence: [
        [:left, ["+", "-"]],
        [:left, ["/", "*"]],
        [:right, ["^"]],
      ]
    )
    @parser = generate_lalr1_parser(@calc2_grammer)
  end

  def test_addition
    tokens = Lexer.new("1 + 2")
    result = @parser.parse(tokens, false)
    assert_equal [:accept, 3], result
  end

  def test_operator_precedence
    tokens = Lexer.new("1 + 2 * 3")
    result = @parser.parse(tokens, false)
    assert_equal [:accept, 7], result
  end

  def test_parentheses
    tokens = Lexer.new("(1 + 2) * 3")
    result = @parser.parse(tokens, false)
    assert_equal [:accept, 9], result
  end

  def test_right_associativity
    tokens = Lexer.new("2 ^ 3 ^ 2")
    result = @parser.parse(tokens, false)
    assert_equal [:accept, 512], result
  end

  def test_syntax_error
    tokens = Lexer.new("1 + * 2")
    result = @parser.parse(tokens, false)
    assert_equal :error, result[0]
  end
end

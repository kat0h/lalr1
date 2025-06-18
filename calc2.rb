require_relative "parsergen_lalr"
require_relative "calc_lex"

Calc2 = Grammer.new(
  vn: Set[:S, :expr, :primary],
  vt: Set["(", ")", "*", "+", "-", "/", "i", :EOF],
  s: :S,
  p: Set[
    Rule.new(:S,    [:expr],              -> v { v[0] }),
    Rule.new(:expr, [:expr, "+", :expr],  -> v { v[0] + v[2] }),
    Rule.new(:expr, [:expr, "/", :expr],  -> v { v[0] / v[2] }),
    Rule.new(:expr, [:primary],           -> v { v[0] }),
    Rule.new(:primary, ["i"], -> v { v[0] }),
    # Rule.new(:expr, [:expr, "*", :expr],  -> v { v[0] * v[2]}),
    # Rule.new(:expr, [:expr, "-", :expr],  -> v { v[0] - v[2]}),
    # Rule.new(:primary, ["(", :expr, ")"], -> v { v[1] }),
  ],
  precedence: [
    [:left, ["+", "-"]],
    [:left, ["/", "*"]],
  ]
)

if __FILE__ == $PROGRAM_NAME
  # p Calc2
  parser = generate_lr1_parser(Calc2, LR1.new(:S, [:expr], 0, :EOF))
  # parser.print_table
  lex = Lexer.new("1+2*3+4")
  p parser.parse lex
end

# expr    : expr '+' expr
#         | expr '-' expr
#         | expr '*' expr
#         | expr '/' expr
#         | primary
#
# primary : NUMBER
#         | '(' expr ')'

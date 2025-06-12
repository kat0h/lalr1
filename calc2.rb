require_relative "parsergen_lalr"
require_relative "calc_lex"

Calc2 = Grammer.new(
  vn: Set[:S, :expr, :primary],
  vt: Set["(", ")", "*", "+", "-", "/", "i", :EOF],
  s: :S,
  p: Set[
    Rule.new(:S,    [:expr],              -> v { v[0] }),
    Rule.new(:expr, [:expr, "+", :expr],  -> v { v[0] + v[2] }),
    Rule.new(:expr, [:expr, "*", :expr],  -> v { v[0] * v[2]}),
    Rule.new(:expr, [:expr, "/", :expr],  -> v { v[0] / v[2] }),
    Rule.new(:expr, [:expr, "-", :expr],  -> v { v[0] - v[2]}),
    Rule.new(:expr, [:primary],           -> v { v[0] }),
    Rule.new(:primary, ["i"], -> v { v[0] }),
    Rule.new(:primary, ["(", :expr, ")"], -> v { v[1] }),
  ],
  precedence: [
  ]
)

if __FILE__ == $PROGRAM_NAME
  parser = generate_lr1_parser(Calc2, LR1.new(:S, [:expr], 0, :EOF))
  parser.print_table
end

# expr    : expr '+' expr
#         | expr '-' expr
#         | expr '*' expr
#         | expr '/' expr
#         | primary
#
# primary : NUMBER
#         | '(' expr ')'

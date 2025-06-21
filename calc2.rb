require_relative "parsergen_lalr"
require_relative "calc_lex"

Calc2 = Grammer.new(
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

def repl
  calc = generate_lalr1_parser(Calc2, LR1.new(:S, [:expr], 0, :EOF))
  calc.print_table
  while true
    begin
      print "calc> "
      input = STDIN.gets
      break if input.nil?
      prompt = input.chomp
      next if prompt.size.zero?
      lex = Lexer.new prompt
      result = calc.parse lex, false
      case result
      in [:accept, n]
        p n
      in [:error, reason]
        p reason
        p Lexer.new(prompt).to_a
      end
    end
  end
end

repl if __FILE__ == $PROGRAM_NAME

# expr    : expr '+' expr
#         | expr '-' expr
#         | expr '*' expr
#         | expr '/' expr
#         | primary
#
# primary : NUMBER
#         | '(' expr ')'

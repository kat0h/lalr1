# reduce/reduceコンフリクトを起こす文法

require_relative "../main"

ReduceReduce = Grammer.new(
  vn: Set[:S, :sequence, :maybeword],
  vt: Set[:word ,:EOF],
  s: :S,
  p: Set[
    Rule.new(:S, [:sequence], -> v {}),
    Rule.new(:sequence, [], -> v {}),
    Rule.new(:sequence, [:maybeword], -> v {}),
    Rule.new(:sequence, [:sequence, :word], -> v {}),
    Rule.new(:maybeword, [], -> v {}),
    Rule.new(:maybeword, [:word], -> v {}),
  ],
  precedence: [
  ]
)

if __FILE__ == $PROGRAM_NAME
  parser = generate_lr1_parser ReduceReduce
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

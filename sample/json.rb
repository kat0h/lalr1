# jsonパーサー

require_relative "../parsergen"

Json = Grammer.new(
  vn: Set[:JSONText, :Value, :Object, :Members, :Member, :Array, :Elements, :String, :Number],
  vt: Set["{", "}", "[", "]", ":", ",", "true", "false", "null", :STRING, :NUMBER, :EOF],
  s: :JSONText,
  p: Set[
    Rule.new(:JSONText, [:Value]),

    Rule.new(:Value, [:String]),
    Rule.new(:Value, [:Number]),
    Rule.new(:Value, [:Object]),
    Rule.new(:Value, [:Array]),
    Rule.new(:Value, ["true"]),
    Rule.new(:Value, ["false"]),
    Rule.new(:Value, ["null"]),

    Rule.new(:Object, ["{", "}"]),
    Rule.new(:Object, ["{", :Members, "}"]),
    Rule.new(:Members, [:Member]),
    Rule.new(:Members, [:Member, ",", :Members]),
    Rule.new(:Member, [:String, ":", :Value]),

    Rule.new(:Array, ["[", "]"]),
    Rule.new(:Array, ["[", :Elements, "]"]),
    Rule.new(:Elements, [:Value]),
    Rule.new(:Elements, [:Value, ",", :Elements]),

    Rule.new(:String, [:STRING]),
    Rule.new(:Number, [:NUMBER]),
  ],
  precedence: []
)


parser = generate_lalr1_parser Json
parser.print_table
lex = ["{", :STRING, ":", "{", :STRING, ":", :NUMBER, "}", "}", :EOF]
p parser.parse lex, true

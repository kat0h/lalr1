require_relative "parsergen_lalr"

conflict = Grammer.new(
  vn: Set[:S, :def, :param_spec, :return_spec, :type, :name, :name_list],
  vt: Set[",", ":", "id", :EOF],
  s: :S,
  p: Set[
    Rule.new(:S, [:def]), # ここの形式は変えない
    Rule.new(:def, [:param_spec, :return_spec, ","]),
    Rule.new(:param_spec, [:type]),
    Rule.new(:param_spec, [:name_list, ":", :type]),
    Rule.new(:return_spec, [:type]),
    Rule.new(:return_spec, [:name, ":", :type]),
    # Rule.new(:return_spec, ["id", "bogus"]),
    Rule.new(:type, ["id"]),
    Rule.new(:name, ["id"]),
    Rule.new(:name_list, [:name]),
    Rule.new(:name_list, [:name, ",", :name_list]),
  ],
)

start = LR1.new(:S, [:def], 0, :EOF)

# i0 = closure conflict, Set[start]
# ca = canonicalset conflict, i0
# ca.each_with_index{puts "\nI#{_2}";printLR1Set(_1,conflict)}

parser = generate_lr1_parser conflict, start
parser.print_table
parser = generate_lalr1_parser conflict, start
parser.print_table

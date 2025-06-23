# https://www.gnu.org/software/bison/manual/html_node/Mysterious-Conflicts.html
# LR(1)文法であるが、LALR(1)文法ではない構文の例

require_relative "../parsergen"

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
  precedence: []
)

parser = generate_lr1_parser conflict
parser.print_table
parser = generate_lalr1_parser conflict
parser.print_table

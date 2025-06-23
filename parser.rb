# rule   : 生成規則の配列   Rule[]
# vn     : 非終端記号の集合 Set[Symbol]
# vt     : 終端記号の集合   Set[Symbol]
# s      : 開始記号         Symbol
# action : 動作表           Action[][] i x t → Action (i ∈ I, t ∈ vt)
# goto   : 行先表           I[][]      i x a → I      (i ∈ I, a ∈ vt)
LR1ParsingTable=Struct.new(:rule,:vn,:vt,:s,:action,:goto,keyword_init:true)do
  def inspect
    ret = "LR1ParsingTable:\n"
    ret << "  rule   :\n"
    rule.each_with_index do |v,i|
      ret << "            #{i}: #{v.inspect}\n"
    end
    ret << "  Vn     : #{vn.to_a.map(&:to_s).join(", ")}\n"
    ret << "  Vt     : #{vt.to_a.map(&:to_s).join(", ")}\n"
    ret << "  s      : #{s}\n"
    ret << "  action :\n"
    ret << "          \t|" << vt.join("\t|") << "\t|\n"
    action.each_with_index do |i,idx|
      ret << "          I#{idx}\t|" << i.map{!_1.nil?? _1.join(""):nil}.join("\t|") << "\t|\n"
    end
    ret << "  goto   : \n"
    ret << ([["     "]+vn.to_a]+goto.each_with_index.map{|i,idx|["I#{idx}",*i.map{!_1.nil?? "I#{_1}":nil}]})
      .filter{!_1[1..].none?}
      .transpose
      .filter{!_1[1..].none?}
      .transpose
      .map{"          "+_1.join("\t|")+"\t|"}
      .join("\n")
    ret
  end
end
class Parser
  def initialize table
    @table = table
    initialize_state
  end
  def initialize_state
    @states = []
    @stack = [0]
    @val = []
  end
  def print_table
    p @table
  end
  def print_state
    puts "states = #{@states.inspect}"
    puts "stack  = #{@stack.inspect}"
    puts "val    = #{@val.inspect}"
  end
  def parse lex,debug=false
    initialize_state
    lex.each do |t, v|
      if debug
        puts
        puts t
        print_state
      end
      a = @table.action[@stack.last][@table.vt.index t]
      p a if debug
      case a
      in [:s, i]
        puts "shift #{i}" if debug
        @stack.push i
        @val.push v
      in [:r, r]
        puts "reduce #{r}" if debug
        pop_count = @table.rule[r].r.size
        @stack.pop pop_count
        @stack.push @table.goto[@stack.last][@table.vn.index(@table.rule[r].l)]
        if act=@table.rule[r].act
          @val.push act.(@val.pop pop_count)
        end
        redo
      in [:a]
        return [:accept, @val.last]
      else
        return [:error, :unexpected_token]
      end
    end
    return [:error, :unexpected_eof] if !@stack.size.zero?
  end
end

def print_table row, col, table
  r = row.to_a
  puts "\t" + col.join("\t")
  table.each_with_index { |i,idx|
    puts ([r[idx]] + i
      .map { _1.nil? ? "." : _1 })
      .join("\t")
  }
end


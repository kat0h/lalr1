Grammer = Struct.new :vn, :vt, :s, :p, :precedence, keyword_init: true do
  def inspect
    ret = "{\n  Vn: {#{vn.to_a.map(&:to_s).join(", ")}}\n"
    ret << "  Vt: {#{vt.to_a.map(&:to_s).join(", ")}}\n"
    ret << "  S: #{s},\n"
    ret << "  P: {\n"
    p.each do
      ret << "    " << it.inspect << ",\n"
    end
    ret << "  }\n"
    ret << "  precedence: #{precedence}\n"
    ret << "}"
  end
end

Rule = Struct.new(:l, :r, :act) do
  def inspect = l.to_s << " → " << r.join(" ")
end

LR0 = Struct.new :l, :r, :dot, :act do
  def inspect
    ret = "[#{l} → "
    r.each_index do |i|
      ret << (i == dot ? "・" : "") + "#{r[i]}" + (i != r.size - 1 ? " " : "")
    end
    ret << "・" if dot == r.size
    ret << "]"
  end
end

LR1 = Struct.new :l, :r, :dot, :ls, :act do
  def complete? = r.size == dot
  def inspect
    ret = "[#{l} → "
    r.each_index do |i|
      ret << (i == dot ? "・" : "") + "#{r[i]}" + (i != r.size - 1 ? " " : "")
    end
    ret << "・" if dot == r.size
    ret << ", #{ls}]"
  end
  def coreeql?(lr1) = l == lr1.l && r == lr1.r && dot == lr1.dot
  def to_rule = Rule.new(l, r, act)
  def lr0 = LR0.new(l, r, dot, act)
  def kernel?(g) = l == g.s || !dot.zero? ? true : false
end

def printLR1Set set, kernel_only=nil # LR(1)項集合を見易く表示するやつ
  q = if kernel_only.nil?
    set.to_a
  else
    set.to_a.select{it.kernel?(kernel_only)}
  end
  while !q.empty?
    i=q.shift;ls=[i.ls]
    q.reject!{i.coreeql?(_1)?ls<<_1.ls: false}
    ret="[#{i.l} → "
    i.r.each_index do
      ret<<(_1==i.dot ? "・":"")+"#{i.r[_1]}"+(_1!=i.r.size-1?" ":"")
    end
    ret<<" ・"if i.dot==i.r.size
    ret<<", #{ls.map{_1==:EOF ??$:_1}.join("/")}]"
    puts ret
  end
end

# first -> 終端記号の集合
# g : Grammer
# a : 記号列
def first g,a,visited=Set[]
  return Set[] if visited.include?(a); visited<<a
  g.vt.include?(a)?Set[a]:g.p.find_all{_1.l==a}.map{first g,_1.r[0],visited}.reduce(&:|)
end

gram = Grammer.new(
  vn: Set[:S, :E, :T, :F],
  vt: Set["(", ")", "*", "+", "i", :EOF],
  s: :S,
  p: Set[
    Rule.new(:S, [:E]), # ここの形式は変えない
    Rule.new(:E, [:E, "+", :T]),
    Rule.new(:E, [:T]),
    Rule.new(:T, [:T, "*", :F]),
    Rule.new(:T, [:F]),
    Rule.new(:F, ["(", :E, ")"]),
    Rule.new(:F, ["i"]),
  ],
)

# (gram.vn | gram.vt).each do
#   puts "first #{it.inspect} = {#{(first gram, it).join(", ")}}"
# end

# closure
# g : Grammer
# i : 状態
def closure g,i
  i_=i.dup
  queue=[*i_]
  while !queue.empty?
    item=queue.shift
    b=item.r[item.dot]
    next if !g.vn.include?(b)
    a2=item.r.slice(item.dot+1..)<< item.ls
    firsts=first(g,a2.first)
    g.p.find_all{_1.l==b}.each{|ruleb|
      firsts.each{|y|
        t=LR1.new(b,ruleb.r,0,y,ruleb.act)
        queue<<t if i_.add? t
      }
    }
  end
  i_
end

# goto -> 状態
# g : Grammer
# i : 状態
# a : 記号
def goto(g,i,a) =
  closure g,i.filter{|t|t.r[t.dot]==a}
  .map{|t|LR1.new(t.l,t.r,t.dot+1,t.ls,t.act)}.to_set

# canonicalset -> 正準集合
# g  : Grammer
# i0 : 初期状態
def canonicalset g,i0
  x,y,s=Set[i0],Set[],g.vn|g.vt
  while !x.empty?
    i=x.first;x.delete i
    y<<i
    s.each do
      id=goto g,i,_1
      next if id.size()==0
      x<<id if !x.include?(id)&&!y.include?(id)
    end
  end
  y
end

# get_precedence -> 優先度(number)
# g : Grammer
# a : 終端記号
def get_precedence(g, a)
  if p=g.precedence.index { it[1].include?(a) }
    p
  else
    nil
  end
end

# get_assoc -> 結合性
# g : Grammer
# a : 終端記号
def get_assoc(g, a)
  if p=g.precedence.index{it[1].include?(a)}
    g.precedence[p][0]
  else
    nil
  end
end


# action -> 動作
# g      : 文法
# ca     : 正準集合
# i      : 状態
# a      : 記号
# accept : 受理するときのLR(1)項
# 動作 ::= sj | rj
# TODO conflict検出
def action(g,ca,i,a,accept)
  act = []
  production_rules = Hash[g.p.each_with_index.to_a]
  ca_i = Hash[ca.each_with_index.to_a]
  # shift
  s = ca_i[goto g, i, a]
  act.push([:s, s]) if !s.nil?
  # reduce
  i.select{_1.complete? && _1.l != g.s}.select{_1.ls==a}.each do|t|
    r = production_rules[t.to_rule]
    act.push([:r, r])
  end
  act.push([:a]) if i.include?(accept) && a == :EOF
  # conflictの解消
  debug = false
  if act.size > 1
    if debug
      puts
      puts "状態#{ca_i[i]}で#{a}が入力の時コンフリクトが検出されました"
      printLR1Set(i)
    end

    act_shift = []
    act_reduce = []
    act.each {
      case it
      in [:s, p]
        act_shift.push p
      in [:r, p]
        act_reduce.push p
      end
    }
    if act_reduce.size > 1
      throw "can't resolve reduce/reduce conflict"
    end
    act_shift = act_shift.first
    act_reduce = act_reduce.first
    # https://github.com/ruby/lrama/blob/00cefd1e5e8cc7564874bab06dffd6cba3af0cc4/lib/lrama/states.rb#L502-L544
    # Shift/Reduce conflict
    # 優先順位を使って解消する
    shiftprec = get_precedence(g, a)
    reduceprec = i.map {|t|
      if t.dot < 2
        nil
      else
        t.r[t.dot-2]
      end
    }.compact.uniq.map{get_precedence(g,it)}.max
    puts "shiftの優先度: #{shiftprec}" if debug
    # 注目点の二つ前の記号の優先順位のうち最大
    puts "reduceの優先度: #{reduceprec}" if debug
    if shiftprec > reduceprec
      puts "> shiftを選択" if debug
      return [:s, act_shift]
    elsif shiftprec < reduceprec
      puts "> reduceを選択" if debug
      return [:r, act_reduce]
    elsif shiftprec == reduceprec
      case get_assoc(g, a)
      in :left
        puts "> reduceを選択" if debug
        return [:r, act_reduce]
      in :right
        puts "> shiftを選択" if debug
        return [:s, act_shift]
      in :noassoc
        throw "not implemented"
      end
    else
      throw "競合を解消できませんでした"
    end
  end
  return act.first
end

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
        @val.push @table.rule[r].act.(@val.pop pop_count)
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

def generate_lr1_parser grammer, start
  i0 = closure grammer, Set[start]
  ca = canonicalset grammer, i0
  ca_indexed = Hash[ca.each_with_index.to_a]
  # ca.each{printLR1Set(it);puts}
  e=start.dup;e.dot=e.r.size;
  action = ca_indexed.keys.map { |i| grammer.vt.map{|a|action grammer,ca,i,a,e} }
  goto = ca_indexed.keys.map{|i|grammer.vn.map{|a|ca_indexed[goto grammer,i,a]}}
  Parser.new(LR1ParsingTable.new(
    rule: grammer.p.to_a,
    vn: grammer.vn.to_a,
    vt: grammer.vt.to_a,
    s: grammer.s,
    action: action,
    goto: goto,
  ))
end
G1 = Grammer.new(
  vn: Set[:S, :E, :T, :F],
  vt: Set["(", ")", "*", "+", "i", :EOF],
  s: :S,
  p: Set[
    Rule.new(:S, [:E],           -> v { v[0] }), # ここの形式は変えない
    Rule.new(:E, [:E, "+", :T],  -> v { ["+", v[0], v[2]] }),
    Rule.new(:E, [:T],           -> v { v[0] }),
    Rule.new(:T, [:T, "*", :F],  -> v { ["*", v[0], v[2]]}),
    Rule.new(:T, [:F],           -> v { v[0] }),
    Rule.new(:F, ["(", :E, ")"], -> v { v[1] }),
    Rule.new(:F, ["i"],          -> v { v[0] }),
  ],
  precedence: []
)


if __FILE__ == $PROGRAM_NAME
  parser = generate_lr1_parser(G1, LR1.new(:S, [:E], 0, :EOF))
  parser.print_table
  lex = ["i", "+", "i", "*", "i", :EOF].zip([3, nil, 4, nil, 7, nil])
  p parser.parse lex, false
end


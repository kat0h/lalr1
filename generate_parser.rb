require_relative "calculation_state"
require_relative "parser"

def generate_lr1_parser grammer
  start = grammer.p.find{ it.l == grammer.s }.to_lr1(0, :EOF)
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

def generate_lalr1_parser grammer
  start = grammer.p.find{ it.l == grammer.s }.to_lr1(0, :EOF)
  i0 = closure grammer, Set[start]

  ca = (canonicalset grammer, i0).to_a
  ca_indexed = Hash[ca.each_with_index.to_a]
  canonicalSet = Struct.new(:_ca, :_cai) do
    def n2i(n) = _ca[n]
    def i2n(i) = _cai[i]
    def print
      puts "size = #{_ca.size}"
      _ca.each{puts; printLR1Set _1}
    end
  end
  lr1cs = canonicalSet.new(ca, ca_indexed)

  # マージできる状態を探索
  def lr1set_core_eql?(a, b)=[a, b].map{_1.map{|s|s.lr0}.to_set}.reduce{_1==_2}
  visited = Array.new(ca.size,0);lst = {}
  while i=visited.index(0) do
    idx=((i+1)...ca.size).select{visited[_1]==0&&lr1set_core_eql?(ca[i],ca[_1])}
    idx.each{visited[_1]=1}
    visited[i]=1
    lst[i]=idx if !idx.empty?
  end
  revlst = {} # マージできる状態のリスト
  lst.each { |k,v| v.each { revlst[_1] = k } }

  # マージした正準集合を求める
  visited = Array.new(ca.size, 0)
  merged_ca = []
  while idx = visited.index(0)
    visited[idx] = 1
    i = lr1cs.n2i(idx).dup
    if !lst[idx].nil?
      lst[idx].each do |n|
        i = i | lr1cs.n2i(n)
        visited[n] = 1
      end
    end
    merged_ca.push(i)
  end
  merged_ca_indexed = Hash[merged_ca.each_with_index.to_a]
  lalr1cs = canonicalSet.new(merged_ca, merged_ca_indexed)
  # merged_ca.each{printLR1Set(it);puts}

  def toLR0set(set) = set.map{it.lr0}.to_set
  v = grammer.vn | grammer.vt
  gototable = merged_ca_indexed.keys.map { |i|
    v.map { |a|
      i_ = goto grammer,i,a
      i__ = merged_ca_indexed.keys.find{
        toLR0set(it) == toLR0set(i_)
      }
      merged_ca_indexed[i__]
    }
  }
  # print_table 0...gototable.size, v, gototable

  # actionのtableを作成
  production_rules = Hash[grammer.p.each_with_index.to_a]
  accept = start.dup; accept.dot = accept.r.size
  action_table = merged_ca_indexed.keys.map do |i|
    grammer.vt.map do |a|
      actions = []
      # shift
      s = gototable[lalr1cs.i2n(i)][v.to_a.index(a)]
      actions.push([:s, s]) if !s.nil?
      # reduce
      i.select{_1.complete? && _1.l != grammer.s}.select{_1.ls==a}.each do|t|
        r = production_rules[t.to_rule]
        actions.push([:r, r])
      end
      # accept
      actions.push([:a]) if i.include?(accept) && a == :EOF
      if actions.size > 1
        resolve_conflict_by_precedence(grammer,i,a,actions,merged_ca_indexed)
      else
        actions.first
      end
    end
  end
  
  Parser.new(LR1ParsingTable.new(
    rule: grammer.p.to_a,
    vn: grammer.vn.to_a,
    vt: grammer.vt.to_a,
    s: grammer.s,
    action: action_table,
    goto: gototable.map{it[...grammer.vn.size]}
  ))
end

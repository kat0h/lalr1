require_relative "resolve_conflict"
# 
# first -> 終端記号の集合
# g : Grammer
# a : 記号列
def first g,a,visited=Set[]
  return Set[] if visited.include?(a); visited<<a
  g.vt.include?(a)?Set[a]:g.p.find_all{_1.l==a}.map{first g,_1.r[0],visited}.reduce(&:|)
end

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

# action -> 動作
# g      : 文法
# ca     : 正準集合
# i      : 状態
# a      : 記号
# accept : 受理するときのLR(1)項
# 動作 ::= sj | rj
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
  if act.size > 1
    return resolve_conflict_by_precedence(g,i,a,act,ca_i,false)
  end
  return act.first
end

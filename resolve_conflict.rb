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

def resolve_conflict_by_precedence(g,i,a,act,ca_i,debug=false)
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
  throw "競合を解消できませんでした" if [shiftprec, reduceprec].compact.size != 2
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

require_relative "lr_n"

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
  def to_lr1(dot, ls) = LR1.new(l, r, dot, ls, act)
end

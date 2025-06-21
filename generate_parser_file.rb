require_relative "calc2"

parser = generate_lalr1_parser(Calc2, LR1.new(:S, [:expr], 0, :EOF))


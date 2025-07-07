require 'minitest/autorun'
require_relative '../main'

class TestConflict < Minitest::Test
  def test_reduce_reduce_conflict
    reduce_reduce_grammer = Grammer.new(
      vn: Set[:S, :sequence, :maybeword],
      vt: Set[:word, :EOF],
      s: :S,
      p: Set[
        Rule.new(:S, [:sequence], -> v {}),
        Rule.new(:sequence, [], -> v {}),
        Rule.new(:sequence, [:maybeword], -> v {}),
        Rule.new(:sequence, [:sequence, :word], -> v {}),
        Rule.new(:maybeword, [], -> v {}),
        Rule.new(:maybeword, [:word], -> v {}),
      ],
      precedence: []
    )

    assert_throws :reduce_reduce_conflict do
      generate_lalr1_parser(reduce_reduce_grammer)
    end
  end
end

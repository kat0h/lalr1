class Lexer
  include Enumerable
  def initialize(input)
    @input = input
    @position = 0
  end
  def next_token
    skip_whitespace
    return nil if eof?
    char = current_char
    case char
    when '+'
      advance
      ["+", nil]
    when '*'
      advance
      ["*", nil]
    when '('
      advance
      ["(", nil]
    when ')'
      advance
      [")", nil]
    when /\d/
      ["i", read_integer]
    else
      raise "Unexpected character: #{char}"
    end
  end
  def each
    while token = next_token
      yield token
    end
    yield [:EOF, nil]
  end
  private
  def current_char = @input[@position]
  def advance = @position += 1
  def skip_whitespace = (advance while current_char =~ /\s/)
  def read_integer
    start = @position
    advance while current_char =~ /\d/
    @input[start...@position].to_i
  end
  def eof? = @position >= @input.length
end


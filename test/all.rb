Dir.glob("test_*.rb", base: __dir__).each { |f|
  p f
  require_relative f
}

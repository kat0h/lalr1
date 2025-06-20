require "js"


trick = ((1..6).to_a+(3..9).to_a+(6..12).to_a+[2]*4).map{|i|("#"*i*4).center(80, " ")}
version = "Hello from #{RUBY_VERSION} (#{RUBY_PLATFORM})"

content = JS.global[:document].querySelector("p")

tid = JS.global.setInterval(proc {
  content[:innerText] = content[:innerText].to_s + "\n" + trick.shift
  JS.global.clearInterval(tid) if trick.empty?
}, 240)

JS.global[:document].querySelector("h2")[:innerText] = version


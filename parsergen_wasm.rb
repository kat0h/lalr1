require 'js'
# https://qiita.com/zifre/items/440c2cdcbb47bfb3d292
module JSRequireRelative
  module_function
  def import(file)
    @pathlist ||= ['']
    file = "#{file}.rb" unless file.end_with?('.rb')
    path = File.absolute_path(file, @pathlist.last)
    @pathlist << File.dirname(path)
    
    path = ".#{path}" if path.start_with?('/')
    evalfile(path)
    @pathlist.pop
  end

  def evalfile(path)
    jsscript = <<~JAVASCRIPT
      const xhr = new XMLHttpRequest()
      xhr.open('GET', '#{path}', false)
      xhr.send()
      return xhr.response
    JAVASCRIPT

    script = JS.eval(jsscript).to_s
    ::TOPLEVEL_BINDING.eval script
  end
end
module Kernel
  alias origin_require_relative require_relative

  def require_relative(path)
    caller_path = caller_locations(1, 1).first.absolute_path || ''
    dir = File.dirname(caller_path)
    file = File.absolute_path(path, dir)
    origin_require_relative(file)
  rescue LoadError
    JSRequireRelative.import(path)
  end
end

p "parsergen wasm loaded!"

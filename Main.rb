require 'optparse'
require_relative 'Backlog'
require_relative 'TimeKeeper'

# 課題をセットする
def set(key)
  tk = TimeKeeper.new
  tk.set(key)
end

# 課題をアンセットする
def unset

end

argv = ARGV.getopts('s:e')
argv['s'] and set(argv['s'])
argv['e'] and unset()

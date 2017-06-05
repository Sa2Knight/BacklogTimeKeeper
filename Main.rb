require 'optparse'
require_relative 'Backlog'
require_relative 'TimeKeeper'

class Main

  def initialize
    @tk = TimeKeeper.new
  end

  # 課題をセットする
  def set(key)
    @tk.is_empty? or raise '課題が作業中です'
    backlog = Backlog.new(:issue_key => key)
    backlog.issueIsExists? or raise '課題が見つかりません'
    @tk.set(key)
  end

  # 課題をアンセットする
  def unset
  end

end

main = Main.new
argv = ARGV.getopts('s:e')
argv['s'] and main.set(argv['s'])
argv['e'] and main.unset()

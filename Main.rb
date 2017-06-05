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
    @tk.is_empty? and raise '課題が設定されていません'
    result = @tk.unset
    backlog = Backlog.new(:issue_key => result[:issue_key])
    backlog.addWorkingTime(result[:diff_hours])
  end

end

main = Main.new
argv = ARGV.getopts('s:e')
argv['s'] and main.set(argv['s'])
argv['e'] and main.unset()

require 'optparse'
require_relative 'Backlog'
require_relative 'TimeKeeper'

class Main

  def initialize
    @tk = TimeKeeper.new
  end

  # 機能1. 課題をセットする
  def set(key)
    backlog = Backlog.new(:issue_key => key)
    @tk.is_empty? or raise '課題が作業中です'
    @tk.set(key)
    puts "#{backlog.getTitle}(#{key})を開始しました"
  end

  # 機能2. 課題をアンセットする
  def unset
    @tk.is_empty? and raise '課題が設定されていません'
    result = @tk.unset
    key = result[:issue_key]
    hours_to_add = result[:diff_hours]
    backlog = Backlog.new(:issue_key => key)
    backlog.addWorkingTime(hours_to_add)
    puts "#{backlog.getTitle}(#{key})を終了し、作業時間を#{hours_to_add.round(2)}時間追加しました"
  end

  # 機能3. 親課題の作業時間を記録する
  def writeParentIssueWorkingTime(key)
    backlog = Backlog.new(:issue_key => key)
    backlog.setWorkingTime(backlog.getChildrenTotalWorkingTime)
  end

end

main = Main.new
argv = ARGV.getopts('s:ep:')
argv['s'] and main.set(argv['s'])
argv['e'] and main.unset()
argv['p'] and main.writeParentIssueWorkingTime(argv['p'])

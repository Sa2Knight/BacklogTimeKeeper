require 'optparse'
require 'date'
require_relative 'Backlog'
require_relative 'BacklogActivities'
require_relative 'TimeKeeper'
require_relative 'Util'

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
  def unset(comment = nil)
    @tk.is_empty? and raise '課題が設定されていません'
    result = @tk.unset
    key = result[:issue_key]
    hours_to_add = result[:diff_hours]
    backlog = Backlog.new(:issue_key => key)
    params = comment ? {:comment => comment} : {}
    backlog.addWorkingTime(hours_to_add, params)
    puts "#{backlog.getTitle}(#{key})を終了し、作業時間を#{hours_to_add.round(2)}時間追加しました"
  end

  # 機能3. 親課題の作業時間を記録する
  def writeParentIssueWorkingTime(key)
    backlog = Backlog.new(:issue_key => key)
    result = backlog.setWorkingTime(backlog.getChildrenTotalWorkingTime)
    result and puts "子課題の累計作業時間(#{result.body.actualHours}時間)を親課題に設定しました"
  end

  # 機能4. 本日の作業ログを出力
  def getTodaysWorkingTimes
    today = Date.today.to_s
    backlog = BacklogActivities.new
    pp backlog.aggregateTotalWorkingTimes(today, today)
  end

  # 機能5. 今週の作業ログを出力
  def getThisWeeksWorkingTimes
    days = Util.getWeeklyDate(Date.today)
    backlog = BacklogActivities.new
    pp backlog.aggregateTotalWorkingTimes(days[:date_from], days[:date_to])
  end

end

main = Main.new
argv = ARGV.getopts('s:ep:m:tw')
argv['s'] and main.set(argv['s'])
argv['e'] and main.unset(argv['m'])
argv['p'] and main.writeParentIssueWorkingTime(argv['p'])
argv['t'] and main.getTodaysWorkingTimes
argv['w'] and main.getThisWeeksWorkingTimes

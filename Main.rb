require 'optparse'
require 'date'
require_relative 'Backlog'
require_relative 'BacklogActivities'
require_relative 'BacklogPostIssue'
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
  def unset
    @tk.is_empty? and raise '課題が設定されていません'
    result = @tk.unset
    key = result[:issue_key]
    hours_to_add = result[:diff_hours]
    backlog = Backlog.new(:issue_key => key)
    params = {comment: %(#{result[:time_from]} 〜 #{result[:time_to]})}
    backlog.addWorkingTime(hours_to_add, params)
    puts "#{backlog.getTitle}(#{key})を終了し、作業時間を#{hours_to_add.round(2)}時間追加しました"
  end

  # 機能3. 親課題の作業時間を記録する
  def writeParentIssueWorkingTime(key)
    backlog = Backlog.new(:issue_key => key)
    begin
      result = backlog.setWorkingTime(backlog.getChildrenTotalWorkingTime).body
      result and puts "子課題の累計作業時間(#{result.actualHours}時間)を親課題(#{result.summary})に設定しました"
    rescue => e
      if e.message == "[ERROR 1] InvalidRequestError - Please change the status or post a comment. (CODE: 7)"
        puts "更新なし: #{key} #{backlog.getTitle}"
      else
        puts "その他のエラーが発生したためプログラムを終了します"
        pp e
        exit
      end
    end
  end

  # 機能4. 未完了全ての親課題について、機能3を実行する
  def writeAllParentIssueWorkingTimes
    backlog = Backlog.new
    incomplete_parent_issues = backlog.getIncompleteParentIssues
    incomplete_parent_issues.each do |issue|
      writeParentIssueWorkingTime(issue)
    end
  end

  # 機能5. 本日の作業ログを出力
  def getTodaysWorkingTimes
    today = Date.today.to_s
    backlog = BacklogActivities.new
    backlog.aggregateTotalWorkingTimes(today, today)
  end

  # 機能6. 今週の作業ログを出力
  def getThisWeeksWorkingTimes
    days = Util.getWeeklyDate(Date.today)
    backlog = BacklogActivities.new
    backlog.aggregateTotalWorkingTimes(days[:date_from], days[:date_to])
  end

  # 機能7. 機能6を使用してBacklogに作業ログを投稿する
  def postThisWeeksWorkingTimes(with_todays)
    opt = {}
    weeks_backlog = BacklogPostIssue.new(getThisWeeksWorkingTimes)
    if with_todays
      todays_logs = getTodaysWorkingTimes
      todays_backlog = BacklogPostIssue.new(getTodaysWorkingTimes)
      opt[:comment] = todays_backlog.makeDescription
    end
    weeks_backlog.postIssue(opt)
  end

  # 機能8. 今月の作業ログを出力
  def getThisMonthWorkingTimes
    days = Util.getMonthlyDate(Date.today)
    backlog = BacklogActivities.new
    backlog.aggregateTotalWorkingTimes(days[:date_from], days[:date_to])
  end

end

main = Main.new
argv = ARGV.getopts('s:ep:PtwcCm')
argv['s'] and main.set(argv['s'])
argv['e'] and main.unset
argv['p'] and main.writeParentIssueWorkingTime(argv['p'])
argv['P'] and main.writeAllParentIssueWorkingTimes
argv['t'] and pp main.getTodaysWorkingTimes
argv['w'] and pp main.getThisWeeksWorkingTimes
argv['m'] and pp main.getThisMonthWorkingTimes
argv['c'] and main.postThisWeeksWorkingTimes(false)
argv['C'] and main.postThisWeeksWorkingTimes(true)

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
    Util.setIssueKeyToChatworkName(key) and puts "チャットワークの表示名を変更完了"
  end

  # 機能2. 課題をアンセットする
  def unset
    @tk.is_empty? and raise '課題が設定されていません'
    result = @tk.unset
    key = result[:issue_key]
    hours_to_add = result[:diff_hours]
    backlog = Backlog.new(:issue_key => key)
    params = {comment: %(#{result[:time_from]} 〜 #{result[:time_to]})}
    Util.resetChatworkName and puts "チャットワークの表示名を変更完了"
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
      todays_backlog = BacklogPostIssue.new(todays_logs)
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

  # 機能9. 機能8を使用してBacklogに作業ログを投稿する
  def postThisMonthWorkingTimes
    month_backlog = BacklogPostIssue.new(getThisMonthWorkingTimes)
    month_backlog.postIssue
  end

end

def help
  puts "s: 課題を開始"
  puts "e: 課題を終了"
  puts "p: 親課題を指定して、子課題の累計作業時間を付与する"
  puts "P: 全ての親課題に対して、各子課題の累計作業時間を付与する"
  puts "t: 本日の作業ログを出力する"
  puts "w: 今週の作業ログを出力する"
  puts "m: 今月の作業ログを出力する"
  puts "c: 今週の作業ログをBacklogに投稿する"
  puts "C: 今週の作業ログをBacklogに投稿し、本日の作業ログをコメントする"
  puts "M: 今月の作業ログをBacklogに投稿する"
  puts "h: オプション一覧を表示"
  exit
end

main = Main.new
argv = ARGV.getopts('hs:ep:PtwcCmM')
argv['h'] and help
argv['s'] and main.set(argv['s'])
argv['e'] and main.unset
argv['p'] and main.writeParentIssueWorkingTime(argv['p'])
argv['P'] and main.writeAllParentIssueWorkingTimes
argv['t'] and pp main.getTodaysWorkingTimes
argv['w'] and pp main.getThisWeeksWorkingTimes
argv['m'] and pp main.getThisMonthWorkingTimes
argv['M'] and main.postThisMonthWorkingTimes
argv['c'] and main.postThisWeeksWorkingTimes(false)
argv['C'] and main.postThisWeeksWorkingTimes(true)

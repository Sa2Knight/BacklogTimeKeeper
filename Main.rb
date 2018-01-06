require 'optparse'
require 'date'
require_relative 'Backlog'
require_relative 'BacklogActivities'
require_relative 'BacklogPostIssue'
require_relative 'TimeKeeper'
require_relative 'Util'

class Main

  WEEKLY_ISSUES_PARENT = 8726828
  MONTHLY_ISSUES_PARENT = 8726829

  def initialize
    @tk = TimeKeeper.new
  end

  # 課題をセットする
  def set(key)
    backlog = Backlog.new(:issue_key => key)
    @tk.is_empty? or raise '課題が作業中です'
    @tk.set(key)
    puts "#{backlog.getTitle}(#{key})を開始しました"
    Util.giveInformationToChatworkName(key) and puts "チャットワークの表示名を変更完了"
    self.displayWorkingTime
  end

  # 課題をアンセットする
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

  # 課題を切り替える
  def swap(key)
    if @tk.is_empty?
      set(key)
    else
      backlog = Backlog.new(:issue_key => key)
      if backlog
        @tk.swap(key)
        Util.giveInformationToChatworkName(key)
      end
    end
  end

  # 現在の課題の作業時間をリアルタイムに標準出力
  def displayWorkingTime
    @tk.is_empty? and raise '課題が設定されていません'
    issue_key = @tk.getIssueKey
    while true
      begin
        diff_string = @tk.getWorkingTimeString
        printf "#{issue_key} #{diff_string}"
        printf "\e[50D"
        STDOUT.flush
        sleep 1
      rescue Interrupt
        puts "\n\n"
        exit
      end
    end
  end

  # 親課題の作業時間を記録する
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

  # 未完了全ての親課題について、機能3を実行する
  def writeAllParentIssueWorkingTimes
    backlog = Backlog.new
    incomplete_parent_issues = backlog.getIncompleteParentIssues
    incomplete_parent_issues.each do |issue|
      writeParentIssueWorkingTime(issue)
    end
  end

  # 本日の作業ログを出力
  def getTodaysWorkingTimes
    today = Date.today.to_s
    backlog = BacklogActivities.new
    backlog.aggregateTotalWorkingTimes(today, today)
  end

  # 今週の作業ログを出力
  def getThisWeeksWorkingTimes
    days = Util.getWeeklyDate(Date.today)
    backlog = BacklogActivities.new
    backlog.aggregateTotalWorkingTimes(days[:date_from], days[:date_to])
  end

  # 今週の作業ログBacklogに投稿する
  def postThisWeeksWorkingTimes(with_todays)
    opt = {}
    weeks_backlog = BacklogPostIssue.new(getThisWeeksWorkingTimes)
    if with_todays
      todays_logs = getTodaysWorkingTimes
      todays_backlog = BacklogPostIssue.new(todays_logs)
      opt[:comment] = todays_backlog.makeDescription
    end
    weeks_backlog.postIssue(WEEKLY_ISSUES_PARENT, opt)
  end

  # 今月の作業ログを出力
  def getThisMonthWorkingTimes
    days = Util.getMonthlyDate(Date.today)
    backlog = BacklogActivities.new
    backlog.aggregateTotalWorkingTimes(days[:date_from], days[:date_to])
  end

  # 今月の作業ログをBacklogに投稿する
  def postThisMonthWorkingTimes
    month_backlog = BacklogPostIssue.new(getThisMonthWorkingTimes)
    month_backlog.postIssue(MONTHLY_ISSUES_PARENT)
  end

  # チャットワークの表示名に昼食中の情報を付与する
  def giveLunchInfomationToChatworkName
    end_time = (DateTime.now + Rational(1, 24)).strftime('~%H:%Mぐらい')
    Util.giveInformationToChatworkName("昼食中(#{end_time})")
  end

  # 定例報告用の、今月と今週の作業レポートを出力する
  def showMonthAndWeeksReport
    backlog = Backlog.new
    month_report = Hash[self.getThisMonthWorkingTimes[:projects].sort_by {|_ ,v| -v[:rate]}]
    weeks_report = self.getThisWeeksWorkingTimes[:projects]
    month_report.keys.concat(weeks_report.keys).uniq.each do |project|
      puts "■ #{backlog.projectKeyToName(project)}"
      puts "\t今月: #{month_report[project][:rate] || 0}%" if month_report[project]
      puts "\t今週: #{weeks_report[project][:rate] || 0}%" if weeks_report[project]
      puts ""
    end
  end

end

def help
  puts "s: 課題を開始"
  puts "e: 課題を終了"
  puts "b: 課題を差し替える"
  puts "t: 進行中の課題の経過時間を表示"
  puts "p: 親課題を指定して、子課題の累計作業時間を付与する"
  puts "P: 全ての親課題に対して、各子課題の累計作業時間を付与する"
  puts "t: 本日の作業ログを出力する"
  puts "w: 今週の作業ログを出力する"
  puts "m: 今月の作業ログを出力する"
  puts "c: 今週の作業ログをBacklogに投稿する"
  puts "C: 今週の作業ログをBacklogに投稿し、本日の作業ログをコメントする"
  puts "l: チャットワークの表示名に'昼食中'を付与する"
  puts "M: 今月の作業ログをBacklogに投稿する"
  puts "l: 現在時刻を元に、昼食中の情報をチャットワークの表示名で通知する"
  puts "r: チャットワークの表示名をリセットする"
  puts "i: 定例報告用の今月/今週の集計情報を出力する"
  puts "h: オプション一覧を表示"
  exit
end

main = Main.new
argv = ARGV.getopts('hs:b:dep:PtwcCmMlri')
argv['h'] and help
argv['s'] and main.set(argv['s'])
argv['b'] and main.swap(argv['b'])
argv['d'] and main.displayWorkingTime
argv['e'] and main.unset
argv['p'] and main.writeParentIssueWorkingTime(argv['p'])
argv['P'] and main.writeAllParentIssueWorkingTimes
argv['t'] and pp main.getTodaysWorkingTimes
argv['w'] and pp main.getThisWeeksWorkingTimes
argv['m'] and pp main.getThisMonthWorkingTimes
argv['M'] and main.postThisMonthWorkingTimes
argv['c'] and main.postThisWeeksWorkingTimes(false)
argv['C'] and main.postThisWeeksWorkingTimes(true)
argv['l'] and main.giveLunchInfomationToChatworkName
argv['r'] and Util.resetChatworkName
argv['i'] and main.showMonthAndWeeksReport

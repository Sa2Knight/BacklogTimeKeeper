require 'date'
require 'pp'
require_relative 'Backlog'
require_relative 'Util'

class BacklogPostIssue < Backlog

  @@PROJECT_ID    = 59599   # プロジェクト: DEVS
  @@ISSUE_TYPE_ID = 265777  # 課題種別: タスク
  @@PRIORITY_ID   = 4       # 優先度:   低
  @@CATEGORY_ID   = 214638  # カテゴリ: 定例

  def initialize(logs, opt = {})
    @logs = logs
    super(opt);
  end

  # 作業ログを投稿
  # 既に該当の課題が存在すればそれの本文を更新
  # 該当する課題が無い場合新規作成
  #-------------------------------------------------
  def postIssue
    current_issue = getIssueBySummary(makeSummary)
    current_issue ? updateIssue(current_issue.id) : createIssue
  end

  # 課題を新規作成して作業ログを投稿
  #----------------------------------
  def createIssue
    params = {
      projectId:   @@PROJECT_ID,
      description: makeDescription,
      assigneeId:  @user.id,
      priorityId:  @@PRIORITY_ID,
      issueTypeId: @@ISSUE_TYPE_ID,
      categoryId:  [@@CATEGORY_ID],
      startDate:   @logs[:date_from].to_s,
      dueDate:     @logs[:date_to].to_s,
    }
    @client.create_issue(makeSummary, params)
  end

  # 課題を更新して作業ログを投稿
  # id: 更新する課題のID
  #------------------------------
  def updateIssue(id)
    @client.update_issue(id, description: makeDescription)
  end

  # 課題タイトルを生成
  #-----------------------------
  def makeSummary
    name = @user.name
    date_from = Util.strToDate(@logs[:date_from]).strftime('%m/%d')
    date_to   = Util.strToDate(@logs[:date_to]).strftime('%m/%d')
    if date_from === date_to
      return "[#{name}] 日報 #{date_from}"
    else
      return "[#{name}] #{date_from}~#{date_to}"
    end
  end

  # 課題本文を生成
  #----------------------------
  def makeDescription
    descriptions = [makeHeader]
    projects = @logs[:projects].sort {|(k1,v1), (k2,v2)| v2[:total] <=> v1[:total]}
    projects.each do |key, val|
      descriptions << makeProjectHeader(key)
      descriptions.concat(makeProjectIssues(key))
    end
    descriptions.join("\n")
  end

  private

    # 全体の見出しを生成
    #------------------------------------
    def makeHeader
      "** 累計 #{@logs[:total]}時間 #{Time.now.strftime('(%m/%d %H:%M 時点)')}"
    end

    # プロジェクトごとの見出しを生成
    # project_key: 対象プロジェクトのキー
    #------------------------------------
    def makeProjectHeader(project_key)
      project = @logs[:projects][project_key]
      return "** #{project_key} #{project[:total]}時間(#{project[:rate]}%)"
    end

    # 課題ごとの作業時間記録を生成
    # project_key: 対象プロジェクトのキー
    #------------------------------------
    def makeProjectIssues(project_key)
      issues = []
      logs = @logs[:projects][project_key][:issues].sort {|a, b| b[:hours] <=> a[:hours]}
      logs.each do |i|
        hours = sprintf('%.2f', i[:hours])
        issues << "- #{i[:key]} #{hours}時間 #{i[:summary]}"
      end
      issues
    end

    # 課題名に合致する課題を取得(複数ある場合も先頭のみ)
    # summary: 対象の課題名
    #----------------------------------------------------
    def getIssueBySummary(summary)
      params = {
        projectId:   [@@PROJECT_ID],
        categoryId: [@@CATEGORY_ID],
        keyword:     summary,
      }
      @client.get_issues(params).body.first
    end

end

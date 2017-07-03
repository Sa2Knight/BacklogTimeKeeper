require 'date'
require 'pp'
require_relative 'Backlog'
require_relative 'Util'

class BacklogPostIssue < Backlog

  @@PROJECT_ID    = 59599   # プロジェクト: DEVS
  @@ISSUE_TYPE_ID = 265777  # 課題種別: タスク
  @@PRIORITY_ID   = 4       # 優先度:   低
  @@CATEGORY_ID   = 214638  # カテゴリ: 定例

  def initialize(logs, params = {})
    @logs = logs
    super(params)
  end

  def postIssue
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

  private

    # 課題タイトルを生成
    def makeSummary
      name = @user.name
      date_from = @logs[:date_from].strftime('%m/%d')
      date_to   = @logs[:date_to].strftime('%m/%d')
      return "[#{name}] #{date_from}~#{date_to}"
    end

    # 課題本文を生成
    def makeDescription
      descriptions = []
      projects = @logs[:projects].sort {|(k1,v1), (k2,v2)| v2[:total] <=> v1[:total]}
      projects.each do |key, val|
        descriptions << makeProjectHeader(key)
        descriptions.concat(makeProjectIssues(key))
      end
      descriptions.join("\n")
    end

    # プロジェクトごとの見出しを生成
    def makeProjectHeader(project_key)
      project = @logs[:projects][project_key]
      return "** #{project_key} #{project[:total]}時間"
    end

    # 課題ごとの作業時間記録を生成
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
    def getIssueBySummary(summary)
      params = {
        projectId:   [@@PROJECT_ID],
        categoryId: [@@CATEGORY_ID],
        keyword:     summary,
      }
      @client.get_issues(params).body.first
    end

end

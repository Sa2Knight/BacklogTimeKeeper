require 'date'
require 'pp'
require_relative 'Backlog'
require_relative 'Util'

class BacklogPostIssue < Backlog

  def initialize(project_key, logs, params = {})
    @project_key = project_key
    @logs = logs
    super(params)
  end

  private

    # プロジェクト名からプロジェクトIDを取得する
    def getProjectId(project_name)
      project = @client.get_project(project_name)
      project.body.id
    end

    # 課題タイトルを生成
    def makeSummary
      name = @user.name
      date_from = @logs[:date_from].strftime('%m/%d')
      date_to   = @logs[:date_to].strftime('%m/%d')
      return "[#{name}] #{date_from}~#{date_to}"
    end

    # 課題本文を生成
    def makeContent
      contents = []
      projects = @logs[:projects].sort {|(k1,v1), (k2,v2)| v2[:total] <=> v1[:total]}
      projects.each do |key, val|
        contents << makeProjectHeader(key)
        contents.concat(makeProjectIssues(key))
      end
      contents.join("\n")
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
        issues << "- #{i[:key]} #{i[:summary]} (#{i[:hours]}時間)"
      end
      issues
    end

end

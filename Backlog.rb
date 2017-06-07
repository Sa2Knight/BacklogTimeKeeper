require 'backlog_kit'
require 'pp'

class Backlog

  # スペースID/APIKey/課題キーを指定してオブジェクトを生成
  def initialize(params = {})
    space_id   = params[:space_id] || ENV['BACKLOG_SPACE']
    api_key    = params[:api_ley]  || ENV['BACKLOGAPI']
    @issue_key = params[:issue_key]
    @client = BacklogKit::Client.new(space_id: space_id, api_key: api_key)
    @user   = @client.get_myself.body
    begin
      @issue_key and @issue = @client.get_issue(@issue_key)
    rescue Exception => e
      p e
      raise 'Backlogから課題を取得できませんでした'
    end
  end

  # 課題のIDを取得する
  def getID
    @issue.body.id
  end

  # 課題のタイトルを取得する
  def getTitle
    @issue.body.summary
  end

  # 自身のアクティビティを取得する
  def activity
  end

  # 作業時間を取得する
  def getWorkingTime
    @issue.body.actualHours || 0
  end

  # 作業時間を書き換える
  def setWorkingTime(new_hours, params = {})
    params[:actualHours] = new_hours.round(2)
    @client.update_issue(@issue_key, params)
  end

  # 作業時間を加算する
  def addWorkingTime(hours_to_add, params = {})
    current_hours = self.getWorkingTime
    new_hours = current_hours + hours_to_add
    self.setWorkingTime(new_hours, params)
  end

  # 子課題の総作業時間を取得する
  def getChildrenTotalWorkingTime
    children = self.getChildren
    children.inject(0) do |total, child|
      child_work_time = child.actualHours || 0
      total + child_work_time
    end
  end

  # 子課題の一覧を取得する
  def getChildren
    params = {parentIssueId: [self.getID]}
    @client.get_issues(params).body
  end

end

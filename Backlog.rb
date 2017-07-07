require 'backlog_kit'
require 'pp'

class Backlog

  @@INCOMPLETE_STATUSES = [1, 2] # 未対応,処理中

  # スペースID/APIKey/課題キーを指定してオブジェクトを生成
  # params: 各種初期化データ 基本的にissue_key以外空で良い
  #--------------------------------------------------------
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
  #--------------------
  def getID
    @issue.body.id
  end

  # 課題のタイトルを取得する
  #-------------------------
  def getTitle
    @issue.body.summary
  end

  # 作業時間を取得する
  #-------------------
  def getWorkingTime
    @issue.body.actualHours || 0
  end

  # 作業時間を書き換える
  # new_hors: 書き換え後の作業時間
  # params:   APIに投げる追加オプション
  #------------------------------------------
  def setWorkingTime(new_hours, params = {})
    params[:actualHours] = new_hours.round(2)
    @client.update_issue(@issue_key, params)
  end

  # 作業時間を加算する
  # hours_to_add: 加算する作業時間
  # params:       APIに投げる追加オプション
  #--------------------------------------------
  def addWorkingTime(hours_to_add, params = {})
    current_hours = self.getWorkingTime
    new_hours = current_hours + hours_to_add
    self.setWorkingTime(new_hours, params)
  end

  # 子課題の総作業時間を取得する
  #-------------------------------
  def getChildrenTotalWorkingTime
    children = self.getChildren
    children.inject(0) do |total, child|
      child_work_time = child.actualHours || 0
      total + child_work_time
    end
  end

  # 子課題の一覧を取得する
  #------------------------
  def getChildren
    params = {parentIssueId: [self.getID], count: 100}
    @client.get_issues(params).body
  end

  # 未完了の親課題の課題キー一覧を取得する
  #----------------------------------------------
  def getIncompleteParentIssues
    params = {
      assigneeId:  [@user.id],
      statusId:    @@INCOMPLETE_STATUSES,
      parentChild: 4 #親課題
    }
    @client.get_issues(params).body.map {|issue| issue.issue_key}
  end

end

require 'backlog_kit'
require 'pp'

class Backlog

  # スペースID/APIKey/課題キーを指定してオブジェクトを生成
  def initialize(params)
    space_id   = params[:space_id] || ENV['BACKLOG_SPACE']
    api_key    = params[:api_ley]  || ENV['BACKLOGAPI']
    @issue_key = params[:issue_key]
    @client = BacklogKit::Client.new(space_id: space_id, api_key: api_key)
    begin
      @issue  = @client.get_issue(@issue_key)
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

  # 作業時間を取得する
  def getWorkingTime
    @issue.body.actualHours || 0
  end

  # 作業時間を書き換える
  def setWorkingTime(new_hours)
    params = {:actualHours => new_hours.round(2)}
    @client.update_issue(@issue_key, params)
  end

  # 作業時間を加算する
  def addWorkingTime(hours_to_add)
    current_hours = self.getWorkingTime
    new_hours = current_hours + hours_to_add
    self.setWorkingTime(new_hours)
  end

end

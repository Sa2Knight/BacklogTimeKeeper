require 'backlog_kit'
require 'pp'

class Backlog

  # スペースID/APIKey/課題キーを指定してオブジェクトを生成
  def initialize(params)
    space_id   = params[:space_id] || ENV['BACKLOG_SPACE']
    api_key    = params[:api_ley]  || ENV['BACKLOGAPI']
    @issue_key = params[:issue_key]
    @client = BacklogKit::Client.new(space_id: space_id, api_key: api_key)
  end

  # 現在の作業時間を取得する
  def getWorkingTime
    issue = @client.get_issue(@issue_key)
    return issue.body.actualHours
  end

  # 課題の作業時間を書き換える
  def writeWorkingTime(new_hours)
    params = {:actualHours => new_hours}
    @client.update_issue(@issue_key, params)
  end

end

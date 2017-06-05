require 'backlog_kit'
require 'pp'

class Backlog

  # スペースIDとAPIKeyを指定してオブジェクトを生成
  def initialize(space_id = nil, api_key = nil)
    space_id or space_id = ENV['BACKLOG_SPACE']
    api_key  or api_key  = ENV['BACKLOGAPI']
    @client = BacklogKit::Client.new(space_id: space_id, api_key: api_key)
  end

  # 課題キーを指定し、現在の作業時間を取得する
  def getWorkingTime(key)
    issue = @client.get_issue(key)
    return issue.body.actualHours
  end

end

require 'backlog_kit'

class Backlog

  def initialize(space_id = nil, api_key = nil)
    space_id or space_id = ENV['BACKLOG_SPACE']
    api_key  or api_key  = ENV['BACKLOGAPI']
    @client = BacklogKit::Client.new(space_id: space_id, api_key: api_key)
  end

end

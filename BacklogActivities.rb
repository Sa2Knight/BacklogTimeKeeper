require 'date'
require_relative 'Backlog'

class BacklogActivities < Backlog

  # Backlogクラスのイニシャライザを呼び、ユーザのアクティビティを取得する
  def initialize(params = {})
    super(params)
    activities_params = {:activityTypeId => [2], :count => 10}
    @activities = @client.get_user_activities(@user.id, activities_params).body
  end

  # アクティビティから、作業時間の変更アクティビティを整形して抜き出す
  def ActivitiesChangeWorkingTimes
    formatted_activities = []
    activities = @activities.each do |activity|
      changed_info = activity.content.changes.find {|c| c.field == 'actualHours'}
      changed_info or next
      formatted_activities.push({
        :datetime  => Time.parse(activity.created),
        :issue_key => "#{activity.project.projectKey}-#{activity.content.key_id}",
        :old_value => changed_info.old_value.to_f,
        :new_value => changed_info.new_value.to_f,
      })
    end
    return formatted_activities
  end

end

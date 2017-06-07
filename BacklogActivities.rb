require 'date'
require_relative 'Backlog'

class BacklogActivities < Backlog

  # Backlogクラスのイニシャライザを呼び、ユーザのアクティビティを取得する
  def initialize(params = {})
    super(params)
    activities_params = {:activityTypeId => [2], :count => 100}
    @activities = @client.get_user_activities(@user.id, activities_params).body
  end

  # アクティビティから、作業時間の変更アクティビティを整形して抜き出す
  def activitiesChangeWorkingTimes
    formatted_activities = []
    activities = @activities.each do |activity|
      changed_info = activity.content.changes.find {|c| c.field == 'actualHours'}
      changed_info or next
      formatted_activities.push({
        :date      => Date.parse(activity.created),
        :issue_key => "#{activity.project.projectKey}-#{activity.content.key_id}",
        :issue_summary => activity.content.summary,
        :old_value => changed_info.old_value.to_f,
        :new_value => changed_info.new_value.to_f,
      })
    end
    return formatted_activities
  end

  # 本日の課題毎の作業時間を集計する
  def todaysTotalWorkingTimes
    aggregate = Hash.new(0)
    activities = self.activitiesChangeWorkingTimes
    todays_activities = activities.select {|a| a[:date].to_s == Date.today.to_s}
    todays_activities.each do |ac|
      aggregate[ac[:issue_key]] += ac[:new_value] - ac[:old_value]
    end
    return aggregate
  end

end

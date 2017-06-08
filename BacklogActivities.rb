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
      changed_info or next        #作業時間の更新がないアクティビティは無視
      formatted_activities.push({
        :date      => Date.parse(activity.created),
        :issue_key => "#{activity.project.projectKey}-#{activity.content.key_id}",
        :old_value => changed_info.old_value.to_f,
        :new_value => changed_info.new_value.to_f,
      })
    end
    return formatted_activities
  end

  # 本日の課題毎の作業時間を集計する
  # 課題数×２回APIを呼んでしまうので注意
  def todaysTotalWorkingTimes
    # アクティビティリストから本日分のアクティビティのみ抜き出す
    today = Date.today.to_s
    aggregate = Hash.new(0)
    activities = self.activitiesChangeWorkingTimes
    todays_activities = activities.select {|a| a[:date].to_s == today}
    todays_activities.each do |ac|
      aggregate[ac[:issue_key]] = (aggregate[ac[:issue_key]] + (ac[:new_value] - ac[:old_value])).round(2)
    end
    # 各課題についての情報を取得し整理、その際に親課題は取り除く
    issues = []
    total_working_time = 0.0
    aggregate.each do |key, val|
      issue_info = @client.get_issue(key).body
      next if self.isParentIssue?(issue_info.id)
      issues.push({
        :key      => issue_info.issueKey,
        :summary  => issue_info.summary,
        :hours    => val,
      })
      total_working_time += val
    end
    return {:date => today, :total => total_working_time.round(2), :issues => issues}
  end

  # 指定した課題が親課題であるかを戻す
  def isParentIssue?(issue_id)
    params = {:parentIssueId => [issue_id]}
    @client.get_issues(params).body.count > 0
  end

end

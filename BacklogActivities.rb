require 'date'
require_relative 'Backlog'

class BacklogActivities < Backlog

  def initialize(params = {})
    super(params)
  end

  # 期間を指定してアクティビティを取得
  def getUserActivities(date_from, date_to)
    activities_params = {:activityTypeId => [2], :count => 100}
    @client.get_user_activities(@user.id, activities_params).body
  end

  # アクティビティから、作業時間の変更アクティビティを整形して抜き出す
  def activitiesChangeWorkingTimes
    activities = self.getUserActivities(nil, nil)
    formatted_activities = []
    activities = activities.each do |activity|
      changed_info = activity.content.changes.find {|c| c.field == 'actualHours'}
      changed_info or next        #作業時間の更新がないアクティビティは無視
      formatted_activities.push({
        :date        => Date.parse(activity.created),
        :issue_key   => "#{activity.project.projectKey}-#{activity.content.key_id}",
        :old_value   => changed_info.old_value.to_f,
        :new_value   => changed_info.new_value.to_f,
      })
    end
    return formatted_activities
  end

  # 本日の課題毎の作業時間を集計する
  # 課題数×２回APIを呼んでしまうので注意
  def todaysTotalWorkingTimes
    # アクティビティリストから本日分のアクティビティのみ抜き出す
    today = '2017-06-14'
    aggregate = Hash.new(0)
    activities = self.activitiesChangeWorkingTimes
    todays_activities = activities.select {|a| a[:date].to_s == today}
    todays_activities.each do |ac|
      aggregate[ac[:issue_key]] = (aggregate[ac[:issue_key]] + (ac[:new_value] - ac[:old_value]))
    end

    # 親課題を取り除く
    aggregate = aggregate.reject do |key, val|
      issue_info = @client.get_issue(key).body
      self.isParentIssue?(issue_info.id)
    end

    # 各課題についてプロジェクトごとに分割しする
    projects = Hash.new {|h, k| h[k] = {total: 0.0, issues: []}}
    aggregate.each do |key, val|
      project_key = key.split('-')[0]
      projects[project_key][:issues].push({
        key:   key,
        hours: val,
      })
    end

    # プロジェクトごとの総作業時間を取得
    projects.keys.each do |key|
      projects[key][:total] = projects[key][:issues].inject(0.0) {|sum, i| sum + i[:hours]}.round(2)
    end

    # 総作業時間を含めて戻す
    return {
      date:     today,
      projects: projects,
      total:    projects.values.inject(0.0) {|sum, p| sum + p[:total]}.round(2),
    }
  end

  # 指定した課題が親課題であるかを戻す
  def isParentIssue?(issue_id)
    params = {:parentIssueId => [issue_id]}
    @client.get_issues(params).body.count > 0
  end

end

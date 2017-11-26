require 'date'
require 'pp'
require_relative 'Backlog'
require_relative 'Util'

class BacklogActivities < Backlog

  @@ACTIVITIES_MAX = 100
  @@SLEEP_SEC      = 2
  @@PARENT_ISSUE_WORD = '【親課題】'

  def initialize(params = {})
    @issues = {}
    super(params)
  end

  # 指定した期間の課題毎の作業時間を集計する
  # date_from : 期間の初日
  # date_to:    期間の最終日
  #--------------------------------------------------
  def aggregateTotalWorkingTimes(date_from, date_to)
    # 指定期間の作業時間に関するアクティビティのみ抜き出す
    aggregate = Hash.new(0)
    activities = activitiesChangeWorkingTimes(date_from, date_to)
    activities.each do |ac|
      aggregate[ac[:issue_key]] = (aggregate[ac[:issue_key]] + (ac[:new_value] - ac[:old_value]))
    end

    # 作業時間が0以下の課題と親課題を取り除く
    aggregate.reject! do |key, val|
      val <= 0.0 || @issues[key][:is_parent]
    end

    # 各課題についてプロジェクトごとに分割しする
    projects = Hash.new {|h, k| h[k] = {total: 0.0, issues: []}}
    aggregate.each do |key, val|
      project_key = key.split('-')[0]
      projects[project_key][:issues].push({
        key:     key,
        summary: @issues[key][:summary],
        hours:   val.round(2),
      })
    end

    # プロジェクトごとの総作業時間を取得
    projects.keys.each do |key|
      projects[key][:total] = projects[key][:issues].inject(0.0) {|sum, i| sum + i[:hours]}.round(2)
    end

    # 全作業時間の和を求め、ソレに対するプロジェクトごとの割合を計算
    total_working_times = projects.values.inject(0.0) {|sum, p| sum + p[:total]}.round(2)
    projects.keys.each do |key|
      projects[key][:rate] = (projects[key][:total] / total_working_times * 100).round(2)
    end

    # 総作業時間を含めて戻す
    return {
      date_from:  date_from,
      date_to:    date_to,
      projects:   projects,
      total:      projects.values.inject(0.0) {|sum, p| sum + p[:total]}.round(2),
    }
  end

  private

    # 期間を指定してアクティビティを取得
    # date_from: 期間の初日
    # date_to:   期間の最終日
    #-----------------------------------------------------
    def getUserActivities(date_from, date_to, params = {})
      params[:count] = @@ACTIVITIES_MAX
      activities = @client.get_user_activities(@user.id, params).body
      require_recursive = (Util.slide9hours(activities[-1].created) > Util.strToDate(date_from))
      activities.select! do |ac|
        addIssue(ac)
        date = Util.slide9hours(ac.created).to_date # タイムゾーン調整
        Util.periodIn?(date, date_from, date_to)
      end
      # 該当のアクティビティを取得しきれなければ再帰呼出し
      if activities && require_recursive
        params[:maxId] = activities[-1].id
        sleep @@SLEEP_SEC
        return activities.concat getUserActivities(date_from, date_to, params)
      else
        return activities
      end
    end

    # アクティビティから、作業時間の変更アクティビティを整形して抜き出す
    # date_from: 期間の初日
    # date_to:   期間の最終日
    #----------------------------------------------------
    def activitiesChangeWorkingTimes(date_from, date_to)
      activities = getUserActivities(date_from, date_to, :activityTypeId => [2])
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

    # アクティビティを元に課題情報をキャッシュする
    # activity: キャッシュするアクティビティ
    #----------------------------------------------
    def addIssue(activity)
      key     = "#{activity.project.projectKey}-#{activity.content.key_id}"
      summary = activity.content.summary
      @issues[key] or @issues[key] = {
        summary:   summary,
        is_parent: !!summary.index(@@PARENT_ISSUE_WORD)
      }
    end

end

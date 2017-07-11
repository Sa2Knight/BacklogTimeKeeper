require 'json'
require 'date'
require 'time'

class TimeKeeper

  @@file_path = './work'

  # 対象ファイルが存在しない場合に作成する
  def initialize
    File.exist?(@@file_path) or File.open(@@file_path, "w").close
  end

  # workログをセット
  def set(key)
    new_params = {:key => key, :datetime => Time.new.to_s}
    self.write_json(new_params)
  end

  # workログをクリアし、課題キーと時間の差分をhoursで戻す
  def unset
    params = load_json
    time_from = Time.parse(params['datetime'])
    time_to   = Time.new
    diff_hours = self.getTimeDiff(time_from, time_to)
    write_json({})
    return {
      :issue_key  => params['key'],
      :diff_hours => diff_hours,
      :time_from  => time_from.strftime('%H:%M'),
      :time_to    => time_to.strftime('%H:%M'),
    }
  end

  # 2つのTimeオブジェクトの時刻差をhoursで戻す
  def getTimeDiff(time_from, time_to)
    diff_sec = (time_to - time_from).to_f
    diff_sec / 60 / 60
  end

  # ログファイルが空であるかをチェック
  def is_empty?
    params = load_json
    return (params && params['key']) ? false : true
  end

  # ログファイルをHashに読み込む
  def load_json
    File.open(@@file_path) do |f|
      JSON.load(f)
    end
  end

  # ログファイルにJSONを書き出す
  def write_json(params)
    File.open(@@file_path, 'w') do |f|
      JSON.dump(params, f)
    end
  end

end

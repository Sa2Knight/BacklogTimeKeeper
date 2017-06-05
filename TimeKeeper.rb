require 'json'
require 'date'
require 'time'

class TimeKeeper

  # workファイルのパスを指定してオブジェクトを生成
  def initialize(file_path)
    @file_path = file_path
  end

  # workログをセット
  def set(key)
    new_params = {:key => key, :datetime => Time.new.to_s}
    self.write_json(new_params)
  end

  # workログをクリアし、時間の差分をhoursで戻す
  def unset
    params = load_json
    time_from = Time.parse(params['datetime'])
    time_to   = Time.new
    diff_hours = self.getTimeDiff(time_from, time_to)
    write_json({})
    return diff_hours
  end

  # 2つのTimeオブジェクトの時刻差をhoursで戻す
  def getTimeDiff(time_from, time_to)
    diff_sec = (time_to - time_from).to_f
    diff_sec / 60 / 60
  end

  # ログファイルをHashに読み込む
  def load_json
    File.open(@file_path) do |f|
      JSON.load(f)
    end
  end

  # ログファイルにJSONを書き出す
  def write_json(params)
    File.open(@file_path, 'w') do |f|
      JSON.dump(params, f)
    end
  end

end

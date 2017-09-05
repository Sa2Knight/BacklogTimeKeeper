require 'date'
class Util

  # 日付文字列をDateオブジェクトに変換する
  # 引数が既にDateの場合そのまま戻す
  def self.strToDate(str)
    str.class == Date   and return str
    str.class == String and return Date.parse(str)
    return nil
  end

  # Dateオブジェクトを文字列に変換する
  # 引数が既に文字列の場合そのまま戻す
  def self.dateToStr(date)
    date.class == Date   and return date.to_s
    date.class == String and return date
  end

  # 指定した日付が特定の期間に含まれているかを戻す
  def self.periodIn?(date, date_from, date_to)
    date      = Util.strToDate(date)
    date_from = Util.strToDate(date_from)
    date_to   = Util.strToDate(date_to)
    return date_from <= date && date <= date_to
  end

  # 指定した日を含む週の月曜日と金曜日の日付を取得
  # 週は月曜に始まり、土日で終了するものとする
  def self.getWeeklyDate(date)
    date  = Util.strToDate(date)
    cwday = date.cwday
    return {
      date_from: date + (1 - cwday),
      date_to:   date + (5 - cwday),
    }
  end

  # 指定した日を含む月の初日と最終日の日付を取得
  def self.getMonthlyDate(date)
    date = Util.strToDate(date)
    return {
      date_from: Date.new(date.year, date.month),
      date_to:   Date.new(date.year, date.month, -1),
    }
  end

  # 2つのTimeオブジェクトの時刻差をhoursで戻す
  def self.getTimeDiffHour(time_from, time_to)
    diff_sec = (time_to - time_from).to_f
    diff_sec / 60 / 60
  end

  # 2つのTimeオブジェクトの時刻さをhh:mm:ssで取得
  def self.getTimeDiffString(time_from, time_to)
    diff_sec = (time_to - time_from).to_i
    hour = 0
    min  = 0
    sec  = 0
    if 60 * 60 < diff_sec
      hour = diff_sec / (60 * 60)
      diff_sec = diff_sec % (60 * 60)
    end
    if 60 < diff_sec
      min = diff_sec / 60
      diff_sec = diff_sec % 60
    end
    sec = diff_sec
    return sprintf("%02d時間%02d分%02d秒", hour, min, sec)
  end

  # 日付時刻文字列を9時間進めてDateTimeオブジェクトに変換する
  def self.slide9hours(datetime)
    datetime.class == String and datetime = DateTime.parse(datetime)
    return datetime + Rational(9, 24)
  end

  # 外部スクリプトを呼び出して、チャットワークの表示名に文字列を付与する
  # チャットワークの本来の表示名は環境変数で渡す
  def self.giveInformationToChatworkName(info)
    name = ENV['CHATWORK_DEFAULT_NAME']
    `python ChangeChatworkName.py "#{name}@#{info}"`
  end

  # 外部スクリプトを呼び出して、チャットワークの表示名を元に戻す
  # チャットワークの本来の表示名は環境変数で渡す
  def self.resetChatworkName
    name = ENV['CHATWORK_DEFAULT_NAME']
    `python ChangeChatworkName.py "#{name}"`
  end

end

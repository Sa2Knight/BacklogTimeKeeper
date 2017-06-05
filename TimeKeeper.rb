require 'json'
require 'date'

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

  # ログファイルにJSONを書き出す
  def write_json(params)
    File.open(@file_path, 'w') do |f|
      JSON.dump(params, f)
    end
  end

end

import time
import json
import sys
from selenium import webdriver
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions
from selenium.webdriver.common.by import By
from pyvirtualdisplay import Display

# 設定ファイル読み込み
with open('secret.json', 'r') as file:
  secret   = json.load(file)
  email    = secret['email']
  password = secret['password']

# Seleniumの前処理
display = Display(visible=0, size=(1920, 1080))
display.start()
driver = webdriver.Firefox()
wait = WebDriverWait(driver, 10)

# チャットワークにログイン
driver.get('https://www.chatwork.com/login.php?lang=ja&args=')
driver.find_element_by_css_selector('form[name="login"] input[name="email"]').send_keys(email)
driver.find_element_by_css_selector('form[name="login"] input[name="password"]').send_keys(password)
driver.find_element_by_css_selector('form[name="login"] input[name="login"]').click()
wait.until(expected_conditions.visibility_of_element_located((By.ID, "_myStatusName")))

# プロフィールを編集画面を表示
driver.find_element_by_css_selector('#_myStatusName').click()
time.sleep(0.5)
driver.find_element_by_css_selector('#_myProfile .myAccountMenu__anchor').click()
time.sleep(0.5)
driver.find_element_by_css_selector('#_profileContent ._profileEdit').click()
time.sleep(0.5)

# 表示名を書き換える
driver.find_element_by_id('_profileInputName').clear()
driver.find_element_by_id('_profileInputName').send_keys(sys.argv[1])

# 保存
driver.find_element_by_css_selector("div[aria-label='保存する']").click()

# 後処理
driver.close()
display.stop()


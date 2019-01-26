require 'google_drive'
require 'm1_api'
require 'stock_quote'
require_relative 'deposit_helpers.rb'

config = YamlHelpers.load_yaml('./config.yml')
accounts = config['accounts']
spreadsheet_id = config['spreadsheet_id']
title = config['title']

creds = M1API.read_credentials
m1 = M1API.new(*creds.values)
m1.query_accounts
session = GoogleDrive::Session.from_service_account_key('credentials.json')
sheet = session.spreadsheet_by_key(spreadsheet_id).worksheet_by_title(title)

if ENV['LIVE_TRANSFER']
  transfer = DepositHelpers.method('transfer')
else
  transfer = DepositHelpers.method('test_transfer')
end

if ENV['LIVE_OUTPUT']
  output = DepositHelpers.method('output')
else
  output = DepositHelpers.method('test_output')
end

accounts.each do |account, configs|
  account_name = configs['target_account']
  price_data = StockQuote::Stock.chart(configs['index'], configs['period']).chart
  performance = price_data[-1]['close'] / price_data[0]['close'] -1
  amount = configs['base_deposit'] * DepositHelpers.calculate_multiplier(performance, configs['performance_multiplier'])
  res = transfer.call(m1, account_name, amount)
  output.call(sheet, res)
end
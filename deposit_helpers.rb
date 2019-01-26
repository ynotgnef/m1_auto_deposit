
module DepositHelpers
  module_function

  def calculate_multiplier(performance, performance_multiplier)
    if performance_multiplier.is_a? Numeric
      performance * performance_multiplier + 1
    else
      1
    end
  end

  def test_transfer(m1, account_name, amount)
    action = amount >= 0 ? 'deposit' : 'withdraw'
    success = true
    { 'account' => account_name,
      'action' => action,
      'amount' => amount,
      'success' => success
    }
  end

  def test_output(sheet, row)
    row['timestamp'] = Time.now
    puts row
  end

  def transfer_successful?(response, action)
    case action
    when 'none'
      'N/A'
    when 'deposit'
      response.dig(:body, 'data', 'createImmediateAchDeposit', 'result', 'didSucceed') == true
    when 'withdraw'
      response.dig(:body, 'data', 'createImmediateAchWithdrawal', 'result', 'didSucceed') == true
    end
  end

  def transfer(m1, account_name, amount)
    account_id = m1.accounts[account_name]
    raise "No account '#{account_name}' found" unless account_id
    m1.query_account_detail(account_id)
    bank_id = m1.accounts_detail[account_id][:bank]['id']
    if amount > 0
      action = 'deposit'
      res = m1.deposit(account_id, bank_id, amount.to_s)
    elsif amount < 0
      action = 'withdraw'
      res = m1.withdraw(account_id, bank_id, (-1*amount).to_s)
    else
      action = 'none'
      res = 0
    end
    {
      'account' => account_name,
      'action' => action,
      'amount' => amount,
      'success' => transfer_successful?(res, action)
    }
  end

  def output(sheet, data)
    data['timestamp'] = Time.now
    out = sheet.rows[0].map { |col| data[col].to_s }
    sheet.insert_rows(2, [out])
    sheet.save
  end

end
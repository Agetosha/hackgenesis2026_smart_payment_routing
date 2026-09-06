module Constraints
  def self.check_hard_constraints(provider, amount, bank)
    return { passed: false, reason: 'inactive_status', details: 'status != active' } if provider['status'] != 'active'
    return { passed: false, reason: 'no_available_requisites', details: 'available_requisites <= 0' } if provider['available_requisites'].to_i <= 0

    min = provider['limit_amount_min']
    max = provider['limit_amount_max']
    return { passed: false, reason: 'amount_below_limit', details: "#{amount} < #{min}" } if min && amount < min
    return { passed: false, reason: 'amount_exceeds_limit', details: "#{amount} > #{max}" } if max && amount > max

    daily_limit = provider['daily_amount_limit']
    daily_current = provider['daily_approved_amount'].to_f
    return { passed: false, reason: 'daily_limit_exceeded', details: "limit #{daily_limit} reached" } if daily_limit && (daily_current + amount > daily_limit)

    if provider['in_progress_count_limit'] && provider['in_progress_count'].to_i >= provider['in_progress_count_limit']
      return { passed: false, reason: 'in_progress_count_limit_exceeded', details: "limit #{provider['in_progress_count_limit']}" }
    end

    banks = provider['banks'] || []
    if bank && !banks.empty?
      is_excluded = provider['exclude_banks']
      bank_in_list = banks.include?(bank.to_s.downcase)
      return { passed: false, reason: 'bank_not_in_list', details: "bank #{bank} not in #{banks}" } if !is_excluded && !bank_in_list
      return { passed: false, reason: 'bank_excluded', details: "bank #{bank} is excluded" } if is_excluded && bank_in_list
    end

    prov_margin = provider['provider_margin_pct'].to_f
    merch_margin = provider['merchant_margin_pct'].to_f
    if !provider['allow_negative_agreement'] && prov_margin > merch_margin
      return { passed: false, reason: 'negative_margin', details: "#{prov_margin} > #{merch_margin}" }
    end

    { passed: true }
  end
end
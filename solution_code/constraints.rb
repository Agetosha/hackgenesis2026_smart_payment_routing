module Constraints
  def self.check_hard_constraints(provider, amount, bank)
    # 1. Статус провайдера
    return { passed: false, reason: 'inactive_status', details: 'status != active' } if provider['status'] != 'active'

    # 2. Проверка нулевого трафика (разрешено только для spacepayments)
    if provider['traffic_percentage'].to_f.zero? && provider['payment_system'] != 'spacepayments'
      return { passed: false, reason: 'zero_traffic_percentage', details: 'traffic_percentage is 0' }
    end

    # 3. Лимиты сумм операции
    min = provider['limit_amount_min']
    max = provider['limit_amount_max']
    return { passed: false, reason: 'amount_below_limit', details: "#{amount} < #{min}" } if min && amount < min
    return { passed: false, reason: 'amount_exceeds_limit', details: "#{amount} > #{max}" } if max && amount > max

    # 4. Дневной лимит оборота
    daily_limit = provider['daily_amount_limit']
    daily_current = provider['daily_approved_amount'].to_f
    if daily_limit && (daily_current + amount > daily_limit)
      return { passed: false, reason: 'daily_limit_exceeded', details: "limit #{daily_limit} reached" }
    end

    # 5. Лимиты операций в обработке (количество и сумма)
    if provider['in_progress_count_limit'] && (provider['in_progress_count'].to_i + 1) > provider['in_progress_count_limit']
      return { passed: false, reason: 'in_progress_count_limit_exceeded', details: "limit #{provider['in_progress_count_limit']}" }
    end

    if provider['in_progress_amount_limit'] && (provider['in_progress_amount'].to_f + amount) > provider['in_progress_amount_limit']
      return { passed: false, reason: 'in_progress_amount_limit_exceeded', details: "limit #{provider['in_progress_amount_limit']}" }
    end

    # 6. Доступность реквизитов
    return { passed: false, reason: 'no_available_requisites', details: 'available_requisites <= 0' } if provider['available_requisites'].to_i <= 0

    # 7. Проверка маржинальности
    prov_margin = provider['provider_margin_pct'].to_f
    merch_margin = provider['merchant_margin_pct'].to_f
    if prov_margin > merch_margin && !provider['allow_negative_agreement']
      return { passed: false, reason: 'negative_margin', details: "#{prov_margin} > #{merch_margin}" }
    end

    # 8. Фильтры банков
    banks = provider['banks'] || []
    if banks.any?
      is_excluded = provider['exclude_banks']
      bank_in_list = banks.include?(bank)
      if is_excluded
        return { passed: false, reason: 'bank_excluded', details: "bank #{bank} is excluded" } if bank_in_list
      else
        return { passed: false, reason: 'bank_not_in_list', details: "bank #{bank} not in #{banks}" } unless bank_in_list
      end
    end

    { passed: true }
  end
end
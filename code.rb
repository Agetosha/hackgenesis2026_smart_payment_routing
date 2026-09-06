require 'json'
require 'date'

# --- 1. ЗАГРУЗКА ДАННЫХ ---
base_dir = __dir__ || '.'
providers_file = File.join(base_dir, 'data', 'providers.json')

queue_file = [
  File.join(base_dir, 'data', 'operations_queue_test.json'),
  File.join(base_dir, 'data', 'operations_queue_10.json'),
  File.join(base_dir, 'data', 'operations_queue.json')
].find { |path| File.exist?(path) }

unless queue_file
  puts "Ошибка: не найден файл очереди в папке data/"
  exit 1
end

providers = JSON.parse(File.read(providers_file))['providers']
queue_data = JSON.parse(File.read(queue_file))

# --- 2. ПРОВЕРКА HARD CONSTRAINTS ---
def check_hard_constraints(provider, amount, bank)
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

# Сортируем строго по приоритету каскада
sorted_providers = providers.sort_by { |p| p['priority'] || 999 }

# --- 3. ЦИКЛ РОУТИНГА ---
results = []
report_stats = { skip_reasons: Hash.new(0), distribution: Hash.new(0) }
total_processed = 0

queue_data.each do |operation|
  op_id = operation['operation_id'] || operation['id']
  amount = (operation['amount'] || operation['sum'] || 0).to_f
  bank = operation['bank'] || operation['bank_name']

  attempts = []
  selected_provider = nil
  simulated_result = "rejected"

  sorted_providers.each do |p|
    p_name = p['payment_system']

    check = check_hard_constraints(p, amount, bank)

    if check[:passed]
      attempts << {
        "provider" => p_name,
        "decision" => "selected",
        "reason" => attempts.empty? ? "primary_priority_match" : "fallback_eligible_provider"
      }
      selected_provider = p_name
      simulated_result = "approved"

      # Обновляем метрики
      p['daily_approved_amount'] = p['daily_approved_amount'].to_f + amount
      p['available_requisites'] = p['available_requisites'].to_i - 1 if p['available_requisites']
      report_stats[:distribution][p_name] += 1
      total_processed += 1
      break
    else
      report_stats[:skip_reasons][check[:reason]] += 1
      attempts << {
        "provider" => p_name,
        "decision" => "skipped",
        "reason" => check[:reason],
        "details" => check[:details]
      }
    end
  end

  results << {
    "operation_id" => op_id,
    "selected_provider" => selected_provider,
    "attempts" => attempts,
    "simulated_result" => simulated_result,
    "latency_sec" => rand(12..35)
  }
end

# --- 4. СОХРАНЕНИЕ РЕШЕНИЙ РОУТИНГА ---
File.write(File.join(base_dir, 'routing_decisions_test.json'), JSON.pretty_generate(results))
File.write(File.join(base_dir, 'routing_decisions.json'), JSON.pretty_generate(results))

# --- 5. ГЕНЕРАЦИЯ ОТЧЕТА ---
report_distribution = {}
utilization = {}
recommendations = []

providers.each do |p|
  p_name = p['payment_system']
  count = report_stats[:distribution][p_name] || 0

  if count > 0 || (p['traffic_percentage'] && p['traffic_percentage'] > 0)
    report_distribution[p_name] = {
      "count" => count,
      "share_pct" => total_processed > 0 ? ((count.to_f / total_processed) * 100).round(1) : 0,
      "target_pct" => p['traffic_percentage'] || 0
    }
  end

  if p['daily_amount_limit'] && p['daily_amount_limit'] > 0
    used = p['daily_approved_amount'].to_f
    limit = p['daily_amount_limit'].to_f
    utilization_pct = (used / limit) * 100
    utilization[p_name] = { "used" => used, "limit" => limit, "utilization_pct" => utilization_pct.round(1) }

    if utilization_pct > 90
      recommendations << "Провайдер #{p_name} почти исчерпал дневной лимит (#{utilization_pct.round(1)}%). Рекомендуется снизить traffic_percentage."
    end
  end
end

if report_stats[:skip_reasons]['bank_not_in_list'] && report_stats[:skip_reasons]['bank_not_in_list'] > (total_processed * 0.3)
  recommendations << "Высокий процент отказов из-за неподдерживаемых банков. Стоит расширить пул провайдеров для популярных банков."
end

report_data = {
  "period" => Date.today.to_s,
  "total_operations" => queue_data.size,
  "distribution" => report_distribution,
  "skip_reasons" => report_stats[:skip_reasons],
  "projected_daily_utilization" => utilization,
  "recommendations" => recommendations
}

File.write(File.join(base_dir, 'routing_report_test.json'), JSON.pretty_generate(report_data))
File.write(File.join(base_dir, 'routing_report.json'), JSON.pretty_generate(report_data))

puts "УСПЕХ!"
puts "- Обработано заявок: #{queue_data.size}"
puts "- Файлы решений и отчета обновлены."
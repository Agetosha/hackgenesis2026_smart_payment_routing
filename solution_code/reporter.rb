require 'date'

module Reporter
  def self.generate(providers, report_stats, total_processed, total_queue_size)
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

    {
      "period" => Date.today.to_s,
      "total_operations" => total_queue_size,
      "distribution" => report_distribution,
      "skip_reasons" => report_stats[:skip_reasons],
      "projected_daily_utilization" => utilization,
      "recommendations" => recommendations
    }
  end
end
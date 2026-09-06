require_relative 'constraints'

module Router
  def self.process(queue_data, providers)
    sorted_providers = providers.sort_by { |p| p['priority'] || 999 }
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
        check = Constraints.check_hard_constraints(p, amount, bank)

        if check[:passed]
          attempts << {
            "provider" => p_name,
            "decision" => "selected",
            "reason" => attempts.empty? ? "primary_priority_match" : "fallback_eligible_provider"
          }
          selected_provider = p_name
          simulated_result = "approved"

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

    { results: results, stats: report_stats, total_processed: total_processed }
  end
end
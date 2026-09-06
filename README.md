<div align="center">

![Ruby](https://img.shields.io/badge/Ruby-CC342D?style=for-the-badge&logo=ruby&logoColor=white)
![JSON](https://img.shields.io/badge/JSON-000000?style=for-the-badge&logo=json&logoColor=white)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen?style=for-the-badge)

</div>

# 💳 Smart Payment Routing Engine

A modular smart payment routing and payout distribution system built with **Ruby**.

The system automatically selects the most suitable payment provider for each transaction based on strict business rules (Hard Constraints), executes cascading fallback logic upon provider rejections, and generates analytical reports with actionable routing recommendations.

---

## ⚡ Quick Start (How to Run)

### Prerequisites
- **Ruby** 2.7 or higher

### 1. Run & Validate for 90-item Queue (Default)
```bash
# Generate decisions for 90 items
ruby solution_code/main.rb

# Validate 90 items
ruby scripts/validate_90.rb routing_decisions_test.json
```
### 2. Run & Validate for 10-item Queue
```Bash
# Temporarily move 90-item queue to process 10-item queue
mv data/operations_queue_90.json ./
ruby solution_code/main.rb
ruby scripts/validate_10.rb routing_decisions_test.json

# Restore 90-item queue
mv operations_queue_90.json data/
ruby solution_code/main.rb
```

---

## 🏗 Project Architecture

```text
.
├── solution_code/
│   ├── main.rb                  # Entry point (Orchestrator)
│   ├── constraints.rb           # Hard Constraints validation module
│   ├── router.rb                # Core cascading routing engine
│   ├── reporter.rb              # Analytics engine & recommendations
│   └── data_loader.rb           # I/O and JSON utility module
├── data/
│   ├── providers.json           # Provider configs, limits, and metrics
│   ├── operations_queue_90.json # Test transaction queue (90 items)
│   ├── operations_queue_10.json # Sample transaction queue (10 items)
│   ├── operations_history.csv   # Historical transaction logs
│   ├── reference_decisions.json # Reference decisions for validation
│   └── sample_routing_decisions.json # Sample of expected routing output
├── scripts/
│   ├── validate_90.rb           # Validation script for 90 items
│   └── validate_10.rb           # Validation script for 10 items
├── routing_decisions.json       # Decision output (standard)
├── routing_decisions_test.json  # Decision output (test auto-check)
├── routing_report.json          # Analytics output (standard)
├── routing_report_test.json     # Analytics output (test auto-check)
└── README.md                    # Documentation

```

---

## 🧩 Module Overview

### 1. `Constraints` (`constraints.rb`)

Enforces strict pre-routing checks. A provider is skipped if any of the following checks fail:

* **Status Check:** Must be `status == 'active'`.
* **Zero Traffic Check:** Providers with `traffic_percentage == 0` are skipped (except fallback providers like `spacepayments`).
* **Amount Limits:** Transaction amount must fall within `[limit_amount_min, limit_amount_max]`.
* **Daily Volume:** `daily_approved_amount + amount` must not exceed `daily_amount_limit`.
* **In-Progress Limits:** Validates both concurrent count (`in_progress_count_limit`) and total pending amount (`in_progress_amount_limit`).
* **Requisites:** Must have `available_requisites > 0`.
* **Bank Restrictions:** Validates bank against `banks` (whitelist) or `exclude_banks` (blacklist).
* **Margin Check:** Prevents negative merchant margin unless explicitly permitted (`allow_negative_agreement`).

### 2. `Router` (`router.rb`)

The core cascading engine:

* Sorts active providers by cascade priority (`priority`).
* Sequentially applies `Constraints.check_hard_constraints`.
* Logs all decision attempts (`attempts`) with detailed reasons (`selected` vs `skipped`).
* Tracks provider traffic distribution and skip statistics in real-time.

### 3. `Reporter` (`reporter.rb`)

Generates post-routing analytics and insights:

* Calculates actual traffic distribution (`share_pct`) vs target distribution (`target_pct`).
* Tracks provider daily limit utilization percentages.
* Generates **automated routing recommendations** (e.g., warnings when daily limits exceed 90% or when bank decline rates spike).

### 4. `DataLoader` (`data_loader.rb`)

Handles filesystem operations securely:

* Smart directory path resolution for running from any context.
* Priority loading for test transaction queues (`operations_queue_*.json`).
* Standardized JSON formatting (`JSON.pretty_generate`).

### 5. `main.rb`

Pipeline orchestrator that ties all modules together and exports the output artifacts to the root directory.

---

## 📊 Output Schema Examples

```json
[
  {
    "operation_id": "op_103",
    "selected_provider": "quickpay",
    "attempts": [
      {
        "provider": "vipay",
        "decision": "skipped",
        "reason": "amount_exceeds_limit",
        "details": "150000 > 100000"
      },
      {
        "provider": "quickpay",
        "decision": "selected",
        "reason": "primary_priority_match"
      }
    ],
    "simulated_result": "approved",
    "latency_sec": 24
  }
]

```

```json
{
  "period": "2026-09-06",
  "total_operations": 90,
  "distribution": {
    "quickpay": {
      "count": 54,
      "share_pct": 60.0,
      "target_pct": 25
    }
  },
  "skip_reasons": {
    "bank_not_in_list": 24,
    "amount_exceeds_limit": 12
  },
  "projected_daily_utilization": {
    "quickpay": {
      "used": 450000.0,
      "limit": 500000.0,
      "utilization_pct": 90.0
    }
  },
  "recommendations": [
    "Provider quickpay is close to reaching its daily limit (90.0%). Consider lowering its target traffic_percentage."
  ]
}

```
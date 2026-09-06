<div align="center">

![Ruby](https://img.shields.io/badge/Ruby-CC342D?style=for-the-badge&logo=ruby&logoColor=white)
![JSON](https://img.shields.io/badge/JSON-000000?style=for-the-badge&logo=json&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen?style=for-the-badge)

</div>

# 💳 Smart Payment Routing Engine

A modular smart payment routing and payout distribution system built with **Ruby**.

The system automatically selects the most suitable payment provider for each transaction based on strict business rules (Hard Constraints), executes cascading fallback logic upon provider rejections, and generates analytical reports with actionable routing recommendations.

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
│   ├── operations_queue_10.json # Sample transaction queue (10 items)
│   ├── operations_history.csv   # Historical transaction logs
│   ├── reference_decisions.json # Reference decisions for validation
│   └── sample_routing_decisions.json # Sample of expected routing output
├── scripts/
│   └── validate_10.rb           # Validation script for 10 items
├── routing_decisions.json       # Decision output (standard)
├── routing_decisions_test.json  # Decision output (test auto-check)
├── routing_report.json          # Analytics output (standard)
├── routing_report_test.json     # Analytics output (test auto-check)
├── README.md                    # Documentation
└── Task_description.docx        # Task description
```

---

## 🧩 Module Overview

### 1. `Constraints` (`constraints.rb`)

Enforces strict pre-routing checks. A provider is skipped if any of the following checks fail:

* **Status Check:** Must be `status == 'active'`.
* **Requisites:** Must have `available_requisites > 0`.
* **Amount Limits:** Transaction amount must fall within `[limit_amount_min, limit_amount_max]`.
* **Daily Volume:** `daily_approved_amount + amount` must not exceed `daily_amount_limit`.
* **In-Progress Limits:** Current concurrent operations must not exceed `in_progress_count_limit`.
* **Bank Restrictions:** Validates bank against `banks` (whitelist) or `exclude_banks` (blacklist).
* **Margin Check:** Prevents negative merchant margin unless explicitly permitted (`allow_negative_agreement`).

### 2. `Router` (`router.rb`)

The core cascading engine:

* Sorts active providers by cascade priority (`priority`).
* Sequentially applies `Constraints.check_hard_constraints`.
* Logs all decision attempts (`attempts`) with detailed reasons (`selected` vs `skipped`).
* Updates provider daily turnover and available requisites in real-time in-memory.

### 3. `Reporter` (`reporter.rb`)

Generates post-routing analytics and insights:

* Calculates actual traffic distribution (`share_pct`) vs target distribution (`target_pct`).
* Tracks provider daily limit utilization percentages.
* Generates **automated routing recommendations** (e.g., warnings when daily limits exceed 90% or when bank decline rates spike).

### 4. `DataLoader` (`data_loader.rb`)

Handles filesystem operations securely:

* Smart directory path resolution for running from any context.
* Priority loading for test transaction queues.
* Standardized JSON formatting (`JSON.pretty_generate`).

### 5. `main.rb`

Pipeline orchestrator that ties all modules together and exports the output artifacts to the root directory.

---

## 🚀 Execution & Testing

### Prerequisites

* **Ruby** 2.7 or higher

### 1. Running the Router

To process the operation queue and generate decision/analytics files, run:

```bash
ruby solution_code/main.rb

```

This updates four output files in the root folder:

* `routing_decisions_test.json` & `routing_decisions.json`
* `routing_report_test.json` & `routing_report.json`

### 2. Validating Results

To run auto-checks on the generated routing decisions:

```bash
ruby validate.rb routing_decisions_test.json

```

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
  "total_operations": 10,
  "distribution": {
    "quickpay": {
      "count": 6,
      "share_pct": 60.0,
      "target_pct": 25
    }
  },
  "skip_reasons": {
    "bank_not_in_list": 4,
    "amount_exceeds_limit": 2
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
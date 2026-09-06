# 💳 Smart Payment Routing Engine

> **HackGenesis 2026 Solution** · Automated payment routing with intelligent provider selection, fallback resilience, and real-time analytics

[![Ruby](https://img.shields.io/badge/Ruby-3.0+-red.svg)](https://www.ruby-lang.org/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Hackathon](https://img.shields.io/badge/HackGenesis-2026-orange.svg)](https://hackgenesis.com)

---

## 📋 Overview

A production-ready payment routing system that intelligently distributes transactions across multiple payment providers based on **hard constraints**, **soft goals**, and **business strategies**. The engine ensures optimal provider selection while maintaining compliance, load balancing, and financial obligations.

### ✨ Key Features

- **🧠 Intelligent Provider Selection** - Multiple routing strategies (traffic share, volume share, cascade, amount ranges, conversion rates)
- **🛡️ Hard Constraints Enforcement** - Strict validation of limits, margins, availability, and bank filters
- **🎯 Soft Goals Optimization** - Traffic distribution targets, conversion prioritization, and financial commitments
- **🔄 Automatic Fallback** - Seamless provider switching on failure with self-provider fallback
- **📊 Comprehensive Analytics** - Distribution reports, utilization tracking, and actionable recommendations
- **🔍 Transparent Decisions** - Detailed reasoning for every choice and skip in the routing process

---

## 🏗️ Architecture

### Input Layer
- `providers.json` - Provider configurations (limits, margins, targets)
- `operations_history.csv` - Historical data for analysis
- `operations_queue.json` - Transaction queue to process

### Routing Engine Core

**Phase 1: Hard Constraint Validation**
- Active status check
- Amount range validation
- Daily limits verification
- In-progress limits
- Bank filters
- Margin checks
- Rate limits
- Available requisites

**Phase 2: Soft Goal Optimization**
- Traffic percentage targets
- Volume distribution
- Priority cascade
- Amount range routing
- Conversion rates
- Load balancing
- Financial commitments

**Phase 3: Provider Selection & Fallback**
- Candidate scoring
- Provider selection
- Retry/fallback logic

### Output Layer
- `routing_decisions.json` - Per-operation decisions with reasoning
- `routing_report.json` - Analytics and recommendations

---

## 🚀 Quick Start

### Prerequisites
- Ruby 3.0 or higher
- Required gems: `json`

### Installation

```bash
# Clone the repository
git clone https://github.com/Agetosha/hackgenesis2026_smart_payment_routing.git
cd hackgenesis2026_smart_payment_routing

# Run the engine
ruby solution_code/main.rb

# Check the solution
ruby scripts/validate_10.rb routing_decisions.json
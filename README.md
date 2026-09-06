# Smart Payment Routing Engine

An automated payout routing mechanism written in Ruby. Designed to distribute payment transactions across multiple providers by enforcing strict hard-constraints, optimizing soft-goals via dynamic scoring, and maintaining cascading fallback logic.

### Key Features
- **Hard-Constraints Engine:** Filters providers by status, daily volume limits, single-transaction bounds, bank support, and margin rules.
- **Smart Scoring (Soft-Goals):** Optimizes candidate selection based on 24h conversion rates, provider priorities, and target traffic percentage balancing.
- **Cascading Fallback:** Automatically switches to alternative eligible providers upon rejection or timeout, falling back to a default self-provider if necessary.
- **Analytics & Reporting:** Generates structured decision logs (`routing_decisions_test.json`) and automated performance metrics/recommendations (`routing_report_test.json`).
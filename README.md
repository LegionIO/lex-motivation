# lex-motivation

Drive-based motivation management for LegionIO agents. Part of the LegionIO cognitive architecture extension ecosystem (LEX).

## What It Does

`lex-motivation` implements a Self-Determination Theory-inspired drive system. Six drives (autonomy, competence, relatedness, novelty, obligation, survival) are updated each tick from real cognitive signals — consent tier, prediction accuracy, trust scores, memory novelty, task backlog, extinction level. The overall motivation mode (approach/avoidance/maintenance/dormant) biases action selection. Goals can be committed to specific drives to track which goals have motivational backing.

Key capabilities:

- **Six drives**: autonomy, competence, relatedness, novelty, obligation, survival
- **EMA smoothing**: drives adapt slowly (alpha=0.1) for stability
- **Four motivation modes**: approach (high intrinsic), avoidance (high extrinsic), maintenance, dormant
- **Burnout detection**: sustained high extrinsic + low intrinsic signal
- **Goal energy**: links specific goals to drive levels for prioritization

## Installation

Add to your Gemfile:

```ruby
gem 'lex-motivation'
```

Or install directly:

```
gem install lex-motivation
```

## Usage

```ruby
require 'legion/extensions/motivation'

client = Legion::Extensions::Motivation::Client.new

# Update from tick results (extracts all drive signals automatically)
client.update_motivation(tick_results: tick_phase_results)

# Manually signal a drive
client.signal_drive(drive: :novelty, value: 0.8)

# Commit a goal to a drive
client.commit_to_goal(goal_id: 'goal-abc123', drive_type: :competence)

# Query drive status
status = client.drive_status
# => { drives: { autonomy: 0.7, competence: 0.6, ... }, mode: :approach,
#      intrinsic_avg: 0.65, extrinsic_avg: 0.3, burnout_risk: false }

# Find which goal has most drive energy
most_energized = client.most_motivated_goal
# => { goal_id: 'goal-abc123', drive: :competence, energy: 0.6 }

# Stats
client.motivation_stats
```

## Runner Methods

| Method | Description |
|---|---|
| `update_motivation` | Extract drive signals from tick results and update all drives |
| `signal_drive` | Explicitly update a single drive |
| `commit_to_goal` | Associate a goal with a drive type |
| `release_goal` | Release a goal commitment |
| `motivation_for` | Current drive level energizing a specific goal |
| `most_motivated_goal` | Goal with highest current drive energy |
| `drive_status` | All drive levels, motivation mode, burnout risk |
| `motivation_stats` | Mode, intrinsic/extrinsic averages, amotivated flag |

## Drive Sources

| Drive | Tick Signal Source |
|---|---|
| autonomy | Consent tier level |
| competence | Prediction accuracy |
| relatedness | Trust score average |
| novelty | Novel memory trace count |
| obligation | Scheduler pending task count |
| survival | Extinction protocol level |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT

# lex-motivation

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-motivation`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::Motivation`

## Purpose

Drive-based motivation management for LegionIO agents. Maintains six drive states (autonomy, competence, relatedness, novelty, obligation, survival) updated via EMA and derived from tick_results signals. Classifies overall motivation mode (approach/avoidance/maintenance/dormant), tracks burnout, detects amotivation, and manages committed goals with drive-weighted energy allocation.

## Gem Info

- **Require path**: `legion/extensions/motivation`
- **Ruby**: >= 3.4
- **License**: MIT
- **Registers with**: `Legion::Extensions::Core`

## File Structure

```
lib/legion/extensions/motivation/
  version.rb
  helpers/
    constants.rb          # Drive types, modes, thresholds, labels
    drive_state.rb        # DriveState with EMA per-drive tracking
    motivation_store.rb   # Goal commitment + energy allocation
  runners/
    motivation.rb         # Runner module

spec/
  legion/extensions/motivation/
    helpers/
      constants_spec.rb
      drive_state_spec.rb
      motivation_store_spec.rb
    runners/motivation_spec.rb
  spec_helper.rb
```

## Key Constants

```ruby
DRIVE_TYPES = %i[autonomy competence relatedness novelty obligation survival]

MOTIVATION_MODES = %i[approach avoidance maintenance dormant]

DRIVE_ALPHA = 0.1    # EMA smoothing for drive updates

INTRINSIC_DRIVES  = %i[autonomy competence relatedness novelty]
EXTRINSIC_DRIVES  = %i[obligation survival]

APPROACH_THRESHOLD   = 0.6   # intrinsic avg >= this -> approach mode
AVOIDANCE_THRESHOLD  = 0.3   # survival/obligation high -> avoidance mode
BURNOUT_THRESHOLD    = 0.15  # sustained high extrinsic + low intrinsic
AMOTIVATION_THRESHOLD = 0.2  # all drives below this -> amotivated

MAX_GOALS = 50
```

## Helpers

### `Helpers::DriveState` (class)

Per-drive EMA tracker with motivation mode classification.

| Attribute | Description |
|---|---|
| `@drives` | Hash of drive_type -> current Float (EMA-smoothed) |
| `@history` | rolling drive history for trend analysis |

| Method | Description |
|---|---|
| `update_drive(drive:, value:)` | EMA-updates a single drive; clamps 0..1 |
| `current_mode` | classifies overall motivation mode from drive levels |
| `overall_level` | mean of all drive levels |
| `intrinsic_average` | mean of INTRINSIC_DRIVES |
| `extrinsic_average` | mean of EXTRINSIC_DRIVES |
| `amotivated?` | all drives below AMOTIVATION_THRESHOLD |
| `decay_all` | decrements all drives by small amount toward resting level |

Mode classification logic:
- `:approach` — intrinsic_average >= APPROACH_THRESHOLD
- `:avoidance` — survival or obligation drive >= AVOIDANCE_THRESHOLD while intrinsic is low
- `:maintenance` — moderate levels, no strong approach or avoidance
- `:dormant` — overall_level below AMOTIVATION_THRESHOLD or amotivated?

### `Helpers::MotivationStore` (class)

Goal commitment and drive-weighted energy allocation.

| Method | Description |
|---|---|
| `commit_goal(goal_id:, drive_type:)` | associates a goal with a specific drive; enforces MAX_GOALS |
| `release_goal(goal_id:)` | removes goal commitment |
| `goal_energy(goal_id:)` | returns current drive level for the goal's associated drive |
| `most_motivated_goal` | goal with highest current drive energy |
| `burnout_check` | true if extrinsic_average high AND intrinsic_average low for sustained ticks |

## Runners

Module: `Legion::Extensions::Motivation::Runners::Motivation`

Private state: `@state` (memoized `DriveState`) and `@store` (memoized `MotivationStore`).

| Runner Method | Parameters | Description |
|---|---|---|
| `update_motivation` | `tick_results: {}` | Extract drive signals from tick_results; update all drives |
| `signal_drive` | `drive:, value:` | Explicitly update a single drive |
| `commit_to_goal` | `goal_id:, drive_type:` | Commit energy from a drive to a goal |
| `release_goal` | `goal_id:` | Release goal commitment |
| `motivation_for` | `goal_id:` | Drive level currently energizing a goal |
| `most_motivated_goal` | (none) | Goal with highest drive energy |
| `drive_status` | (none) | All drive levels, mode, burnout risk |
| `motivation_stats` | (none) | Mode, intrinsic avg, extrinsic avg, amotivated flag |

`update_motivation` extracts from tick_results:
- `autonomy` — from consent tier level (higher autonomy tier -> higher drive)
- `competence` — from prediction accuracy
- `relatedness` — from trust score average
- `novelty` — from count of novel memory traces retrieved
- `obligation` — from scheduler pending task count
- `survival` — from extinction protocol level (inverted: level > 0 raises survival drive)

## Integration Points

- **lex-goal-management**: `commit_to_goal` links motivation energy to specific goals in lex-goal-management. Most-motivated goals should be prioritized in `highest_priority_goals` calls.
- **lex-volition**: `lex-volition` forms intentions; motivation energy determines which intentions are pursued. Drive status feeds the `form_intentions` phase.
- **lex-tick**: `update_motivation` is wired into `action_selection` phase to provide drive context for action choice.
- **lex-consent**: consent tier is the proxy for autonomy drive level.
- **lex-extinction**: extinction level signals survival drive urgency.
- **lex-metacognition**: `Motivation` is listed under `:motivation` capability category.

## Development Notes

- Drive values are initialized to 0.5 (moderate) on first access. There is no cold-start at zero.
- `burnout_check` uses a sustained threshold — it requires multiple consecutive ticks of high extrinsic + low intrinsic, not a single tick reading. The sustain window is configurable in the implementation but not exposed as a constant.
- `update_motivation` extracts signals from tick_results keys that may not exist (defensive extraction via `dig` with nil fallback). Missing phases return 0.0 signal contribution.
- DRIVE_ALPHA of 0.1 creates very slow adaptation. At this alpha, a drive shift from 0.5 to 0.9 takes approximately 18 ticks to reach 80% of target.
- `amotivated?` checks all drives simultaneously — even one drive above threshold prevents amotivation diagnosis.
- No actor; drive decay is driven by `update_motivation` each tick.

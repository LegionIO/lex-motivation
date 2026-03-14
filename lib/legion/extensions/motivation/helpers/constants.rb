# frozen_string_literal: true

module Legion
  module Extensions
    module Motivation
      module Helpers
        module Constants
          # Drive types based on Self-Determination Theory + survival/obligation
          DRIVE_TYPES = %i[autonomy competence relatedness novelty obligation survival].freeze

          # Motivation operating modes (approach/avoidance model)
          MOTIVATION_MODES = %i[approach avoidance maintenance dormant].freeze

          # EMA alpha for drive level tracking (slow adaptation)
          DRIVE_ALPHA = 0.1

          # Intrinsic drives (Self-Determination Theory: autonomy, competence, relatedness + novelty)
          INTRINSIC_DRIVES = %i[autonomy competence relatedness novelty].freeze

          # Extrinsic drives (external pressure: obligation, survival)
          EXTRINSIC_DRIVES = %i[obligation survival].freeze

          # Per-tick drive decay rate
          DRIVE_DECAY_RATE = 0.02

          # Maximum goals tracked simultaneously
          MAX_GOALS = 50

          # Above this overall level, agent is in approach mode
          APPROACH_THRESHOLD = 0.6

          # Below this, agent is in avoidance mode
          AVOIDANCE_THRESHOLD = 0.3

          # Below this across individual drives, drive is in burnout
          BURNOUT_THRESHOLD = 0.15

          # Below this across ALL drives, agent is amotivated
          AMOTIVATION_THRESHOLD = 0.2
        end
      end
    end
  end
end

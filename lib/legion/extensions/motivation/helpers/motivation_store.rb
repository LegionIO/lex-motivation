# frozen_string_literal: true

module Legion
  module Extensions
    module Motivation
      module Helpers
        class MotivationStore
          attr_reader :drive_state, :goal_motivations

          def initialize(drive_state: nil)
            @drive_state      = drive_state || DriveState.new
            @goal_motivations = {}
            @low_motivation_ticks = 0
          end

          def commit_goal(goal_id, drives)
            valid_drives = Array(drives).select { |d| Constants::DRIVE_TYPES.include?(d) }
            return false if valid_drives.empty?

            trim_goals
            @goal_motivations[goal_id] = {
              drives:       valid_drives,
              energy:       goal_energy_for(valid_drives),
              committed:    true,
              committed_at: Time.now.utc
            }
            true
          end

          def release_goal(goal_id)
            @goal_motivations.delete(goal_id)
            true
          end

          def goal_energy(goal_id)
            entry = @goal_motivations[goal_id]
            return 0.0 unless entry

            entry[:energy] = goal_energy_for(entry[:drives])
            entry[:energy]
          end

          def most_motivated_goal
            return nil if @goal_motivations.empty?

            refreshed = @goal_motivations.transform_values do |entry|
              entry.merge(energy: goal_energy_for(entry[:drives]))
            end

            best_id, best_entry = refreshed.max_by { |_, v| v[:energy] }
            return nil unless best_id

            { goal_id: best_id, energy: best_entry[:energy].round(4), drives: best_entry[:drives] }
          end

          def burnout_check
            overall = @drive_state.overall_level
            if overall < Constants::BURNOUT_THRESHOLD
              @low_motivation_ticks += 1
            else
              @low_motivation_ticks = 0
            end

            {
              burnout:              @low_motivation_ticks >= 10,
              low_motivation_ticks: @low_motivation_ticks,
              overall_level:        overall.round(4)
            }
          end

          def stats
            {
              overall_level:        @drive_state.overall_level.round(4),
              current_mode:         @drive_state.current_mode,
              intrinsic_average:    @drive_state.intrinsic_average.round(4),
              extrinsic_average:    @drive_state.extrinsic_average.round(4),
              amotivated:           @drive_state.amotivated?,
              goal_count:           @goal_motivations.size,
              low_motivation_ticks: @low_motivation_ticks
            }
          end

          private

          def goal_energy_for(drives)
            return 0.0 if drives.empty?

            total = drives.sum { |d| @drive_state.drive_level(d) }
            (total / drives.size.to_f).clamp(0.0, 1.0)
          end

          def trim_goals
            return unless @goal_motivations.size >= Constants::MAX_GOALS

            oldest_key = @goal_motivations.min_by { |_, v| v[:committed_at] }&.first
            @goal_motivations.delete(oldest_key) if oldest_key
          end
        end
      end
    end
  end
end

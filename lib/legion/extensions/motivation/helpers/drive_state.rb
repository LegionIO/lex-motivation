# frozen_string_literal: true

module Legion
  module Extensions
    module Motivation
      module Helpers
        class DriveState
          attr_reader :drives

          def initialize
            @drives = Constants::DRIVE_TYPES.to_h do |type|
              [type, { level: 0.5, satisfied: false, last_signal: nil }]
            end
          end

          def update_drive(type, signal)
            return unless Constants::DRIVE_TYPES.include?(type)

            clamped = signal.clamp(0.0, 1.0)
            current = @drives[type][:level]
            @drives[type][:level]       = ema(current, clamped, Constants::DRIVE_ALPHA)
            @drives[type][:satisfied]   = @drives[type][:level] >= 0.6
            @drives[type][:last_signal] = Time.now.utc
          end

          def drive_level(type)
            return 0.0 unless Constants::DRIVE_TYPES.include?(type)

            @drives[type][:level]
          end

          def satisfied?(type)
            return false unless Constants::DRIVE_TYPES.include?(type)

            @drives[type][:satisfied]
          end

          def intrinsic_average
            levels = Constants::INTRINSIC_DRIVES.map { |d| @drives[d][:level] }
            mean(levels)
          end

          def extrinsic_average
            levels = Constants::EXTRINSIC_DRIVES.map { |d| @drives[d][:level] }
            mean(levels)
          end

          def overall_level
            all_levels = @drives.values.map { |d| d[:level] }
            mean(all_levels)
          end

          def current_mode
            level = overall_level
            if level >= Constants::APPROACH_THRESHOLD
              :approach
            elsif level <= Constants::BURNOUT_THRESHOLD
              :dormant
            elsif level <= Constants::AVOIDANCE_THRESHOLD
              :avoidance
            else
              :maintenance
            end
          end

          def decay_all
            @drives.each_key do |type|
              current = @drives[type][:level]
              decayed = [current - Constants::DRIVE_DECAY_RATE, 0.0].max
              @drives[type][:level]     = decayed
              @drives[type][:satisfied] = decayed >= 0.6
            end
          end

          def amotivated?
            @drives.values.all? { |d| d[:level] < Constants::AMOTIVATION_THRESHOLD }
          end

          private

          def ema(current, observed, alpha)
            (current * (1.0 - alpha)) + (observed * alpha)
          end

          def mean(values)
            return 0.0 if values.empty?

            values.sum / values.size.to_f
          end
        end
      end
    end
  end
end

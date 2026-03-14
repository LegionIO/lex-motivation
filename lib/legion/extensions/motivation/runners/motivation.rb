# frozen_string_literal: true

module Legion
  module Extensions
    module Motivation
      module Runners
        module Motivation
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def update_motivation(tick_results: {}, **)
            extract_drive_signals(tick_results)
            motivation_store.drive_state.decay_all
            burnout = motivation_store.burnout_check
            mode    = motivation_store.drive_state.current_mode

            Legion::Logging.debug "[motivation] mode=#{mode} " \
                                  "overall=#{motivation_store.drive_state.overall_level.round(3)} " \
                                  "amotivated=#{motivation_store.drive_state.amotivated?}"

            {
              mode:              mode,
              overall_level:     motivation_store.drive_state.overall_level.round(4),
              intrinsic_average: motivation_store.drive_state.intrinsic_average.round(4),
              extrinsic_average: motivation_store.drive_state.extrinsic_average.round(4),
              amotivated:        motivation_store.drive_state.amotivated?,
              burnout:           burnout[:burnout]
            }
          end

          def signal_drive(drive:, signal:, **)
            drive_sym = drive.to_sym
            return { success: false, error: "unknown drive: #{drive}" } unless Helpers::Constants::DRIVE_TYPES.include?(drive_sym)

            motivation_store.drive_state.update_drive(drive_sym, signal.to_f)
            level = motivation_store.drive_state.drive_level(drive_sym)

            Legion::Logging.debug "[motivation] drive signal: #{drive_sym}=#{level.round(3)}"
            { success: true, drive: drive_sym, level: level.round(4) }
          end

          def commit_to_goal(goal_id:, drives:, **)
            drive_syms = Array(drives).map(&:to_sym)
            result = motivation_store.commit_goal(goal_id, drive_syms)

            if result
              energy = motivation_store.goal_energy(goal_id)
              Legion::Logging.info "[motivation] committed goal=#{goal_id} energy=#{energy.round(3)}"
              { success: true, goal_id: goal_id, energy: energy.round(4) }
            else
              Legion::Logging.warn "[motivation] commit_goal rejected: no valid drives for #{goal_id}"
              { success: false, error: 'no valid drives provided' }
            end
          end

          def release_goal(goal_id:, **)
            motivation_store.release_goal(goal_id)
            Legion::Logging.debug "[motivation] released goal=#{goal_id}"
            { success: true, goal_id: goal_id }
          end

          def motivation_for(goal_id:, **)
            energy = motivation_store.goal_energy(goal_id)
            Legion::Logging.debug "[motivation] motivation_for goal=#{goal_id} energy=#{energy.round(3)}"
            { goal_id: goal_id, energy: energy.round(4) }
          end

          def most_motivated_goal(**)
            result = motivation_store.most_motivated_goal
            Legion::Logging.debug "[motivation] most_motivated_goal=#{result&.fetch(:goal_id, nil)}"
            result || { goal_id: nil, energy: 0.0, drives: [] }
          end

          def drive_status(**)
            drives = motivation_store.drive_state.drives.transform_values do |d|
              { level: d[:level].round(4), satisfied: d[:satisfied] }
            end

            Legion::Logging.debug '[motivation] drive_status'
            {
              drives:  drives,
              mode:    motivation_store.drive_state.current_mode,
              overall: motivation_store.drive_state.overall_level.round(4)
            }
          end

          def motivation_stats(**)
            Legion::Logging.debug '[motivation] stats'
            motivation_store.stats
          end

          private

          def motivation_store
            @motivation_store ||= Helpers::MotivationStore.new
          end

          def extract_drive_signals(tick_results)
            extract_autonomy_signal(tick_results)
            extract_competence_signal(tick_results)
            extract_relatedness_signal(tick_results)
            extract_novelty_signal(tick_results)
            extract_obligation_signal(tick_results)
            extract_survival_signal(tick_results)
          end

          def extract_autonomy_signal(tick_results)
            consent_tier = tick_results.dig(:consent, :tier)
            return unless consent_tier

            signal = case consent_tier
                     when :autonomous then 1.0
                     when :collaborate then 0.7
                     when :consult     then 0.4
                     else 0.1
                     end
            motivation_store.drive_state.update_drive(:autonomy, signal)
          end

          def extract_competence_signal(tick_results)
            accuracy = tick_results.dig(:prediction_engine, :accuracy)
            return unless accuracy

            motivation_store.drive_state.update_drive(:competence, accuracy.to_f)
          end

          def extract_relatedness_signal(tick_results)
            trust_level = tick_results.dig(:trust, :overall_level)
            return unless trust_level

            motivation_store.drive_state.update_drive(:relatedness, trust_level.to_f)
          end

          def extract_novelty_signal(tick_results)
            novel = tick_results.dig(:memory_retrieval, :novel_traces)
            return unless novel

            signal = novel.positive? ? [novel.to_f / 10.0, 1.0].min : 0.1
            motivation_store.drive_state.update_drive(:novelty, signal)
          end

          def extract_obligation_signal(tick_results)
            pending = tick_results.dig(:scheduler, :pending_tasks)
            return unless pending

            signal = pending.positive? ? [pending.to_f / 20.0, 1.0].min : 0.0
            motivation_store.drive_state.update_drive(:obligation, signal)
          end

          def extract_survival_signal(tick_results)
            extinction_level = tick_results.dig(:extinction, :level)
            return unless extinction_level

            signal = extinction_level.to_f / 4.0
            motivation_store.drive_state.update_drive(:survival, signal)
          end
        end
      end
    end
  end
end

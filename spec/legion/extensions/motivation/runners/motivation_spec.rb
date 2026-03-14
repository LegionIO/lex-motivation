# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Motivation::Runners::Motivation do
  let(:client) { Legion::Extensions::Motivation::Client.new }

  let(:normal_tick) do
    {
      consent:           { tier: :collaborate },
      prediction_engine: { accuracy: 0.8 },
      trust:             { overall_level: 0.7 },
      memory_retrieval:  { novel_traces: 3 },
      scheduler:         { pending_tasks: 5 },
      extinction:        { level: 0 }
    }
  end

  let(:adverse_tick) do
    {
      consent:           { tier: :supervised },
      prediction_engine: { accuracy: 0.2 },
      trust:             { overall_level: 0.1 },
      memory_retrieval:  { novel_traces: 0 },
      scheduler:         { pending_tasks: 0 },
      extinction:        { level: 3 }
    }
  end

  describe '#update_motivation' do
    it 'returns a hash with expected keys' do
      result = client.update_motivation(tick_results: normal_tick)
      expect(result).to include(:mode, :overall_level, :intrinsic_average,
                                :extrinsic_average, :amotivated, :burnout)
    end

    it 'returns a valid mode symbol' do
      result = client.update_motivation(tick_results: normal_tick)
      expect(Legion::Extensions::Motivation::Helpers::Constants::MOTIVATION_MODES).to include(result[:mode])
    end

    it 'handles empty tick results' do
      result = client.update_motivation(tick_results: {})
      expect(result[:overall_level]).to be_a(Float)
    end

    it 'handles missing tick keys gracefully' do
      result = client.update_motivation(tick_results: { trust: {} })
      expect(result).to include(:mode)
    end

    it 'returns amotivated as false initially' do
      result = client.update_motivation(tick_results: {})
      expect(result[:amotivated]).to be false
    end

    it 'decays drives on each tick' do
      initial = client.motivation_store.drive_state.overall_level
      client.update_motivation(tick_results: {})
      after = client.motivation_store.drive_state.overall_level
      expect(after).to be < initial
    end
  end

  describe '#signal_drive' do
    it 'updates a valid drive' do
      result = client.signal_drive(drive: :autonomy, signal: 0.9)
      expect(result[:success]).to be true
      expect(result[:drive]).to eq(:autonomy)
      expect(result[:level]).to be_a(Float)
    end

    it 'accepts string drive names' do
      result = client.signal_drive(drive: 'competence', signal: 0.7)
      expect(result[:success]).to be true
    end

    it 'rejects unknown drive' do
      result = client.signal_drive(drive: :nonexistent, signal: 0.5)
      expect(result[:success]).to be false
      expect(result[:error]).to include('unknown drive')
    end

    it 'reflects updated level in drive_status' do
      client.signal_drive(drive: :novelty, signal: 1.0)
      status = client.drive_status
      expect(status[:drives][:novelty][:level]).to be > 0.5
    end
  end

  describe '#commit_to_goal' do
    it 'commits a goal with valid drives' do
      result = client.commit_to_goal(goal_id: 'goal_a', drives: %i[autonomy competence])
      expect(result[:success]).to be true
      expect(result[:goal_id]).to eq('goal_a')
      expect(result[:energy]).to be_a(Float)
    end

    it 'returns failure for entirely invalid drives' do
      result = client.commit_to_goal(goal_id: 'bad', drives: [:nonexistent])
      expect(result[:success]).to be false
      expect(result[:error]).to be_a(String)
    end
  end

  describe '#release_goal' do
    it 'releases a committed goal' do
      client.commit_to_goal(goal_id: 'temp_goal', drives: [:autonomy])
      result = client.release_goal(goal_id: 'temp_goal')
      expect(result[:success]).to be true
      expect(client.motivation_store.goal_motivations).not_to have_key('temp_goal')
    end

    it 'succeeds for unknown goal id' do
      result = client.release_goal(goal_id: 'no_such_goal')
      expect(result[:success]).to be true
    end
  end

  describe '#motivation_for' do
    it 'returns 0.0 energy for uncommitted goal' do
      result = client.motivation_for(goal_id: 'unknown_goal')
      expect(result[:energy]).to eq(0.0)
    end

    it 'returns positive energy for committed goal' do
      client.commit_to_goal(goal_id: 'tracked', drives: %i[autonomy competence])
      result = client.motivation_for(goal_id: 'tracked')
      expect(result[:energy]).to be >= 0.0
    end

    it 'includes goal_id in result' do
      result = client.motivation_for(goal_id: 'some_goal')
      expect(result[:goal_id]).to eq('some_goal')
    end
  end

  describe '#most_motivated_goal' do
    it 'returns nil goal_id when no goals committed' do
      result = client.most_motivated_goal
      expect(result[:goal_id]).to be_nil
    end

    it 'returns the most energized goal' do
      client.commit_to_goal(goal_id: 'low', drives: [:obligation])
      client.commit_to_goal(goal_id: 'high', drives: %i[autonomy competence relatedness novelty])
      %i[autonomy competence relatedness novelty].each do |d|
        5.times { client.signal_drive(drive: d, signal: 1.0) }
      end
      result = client.most_motivated_goal
      expect(result[:goal_id]).to eq('high')
    end

    it 'includes energy and drives in result' do
      client.commit_to_goal(goal_id: 'g1', drives: [:autonomy])
      result = client.most_motivated_goal
      expect(result).to include(:goal_id, :energy, :drives)
    end
  end

  describe '#drive_status' do
    it 'returns drives hash' do
      status = client.drive_status
      expect(status).to have_key(:drives)
    end

    it 'returns mode' do
      status = client.drive_status
      expect(status).to have_key(:mode)
    end

    it 'returns overall level' do
      status = client.drive_status
      expect(status).to have_key(:overall)
    end

    it 'includes level and satisfied for each drive type' do
      status = client.drive_status
      Legion::Extensions::Motivation::Helpers::Constants::DRIVE_TYPES.each do |type|
        expect(status[:drives][type]).to include(:level, :satisfied)
      end
    end
  end

  describe '#motivation_stats' do
    it 'returns overall_level' do
      expect(client.motivation_stats).to have_key(:overall_level)
    end

    it 'returns current_mode' do
      expect(client.motivation_stats).to have_key(:current_mode)
    end

    it 'returns intrinsic_average' do
      expect(client.motivation_stats).to have_key(:intrinsic_average)
    end

    it 'returns extrinsic_average' do
      expect(client.motivation_stats).to have_key(:extrinsic_average)
    end

    it 'returns amotivated flag' do
      expect(client.motivation_stats).to have_key(:amotivated)
    end

    it 'returns goal_count' do
      expect(client.motivation_stats).to have_key(:goal_count)
    end
  end

  describe 'drive signal extraction from tick results' do
    it 'extracts autonomy from consent tier :autonomous' do
      client.update_motivation(tick_results: { consent: { tier: :autonomous } })
      expect(client.motivation_store.drive_state.drive_level(:autonomy)).to be > 0.5
    end

    it 'extracts competence from prediction accuracy' do
      client.update_motivation(tick_results: { prediction_engine: { accuracy: 0.95 } })
      expect(client.motivation_store.drive_state.drive_level(:competence)).to be > 0.5
    end

    it 'extracts relatedness from trust level' do
      client.update_motivation(tick_results: { trust: { overall_level: 0.9 } })
      expect(client.motivation_store.drive_state.drive_level(:relatedness)).to be > 0.5
    end

    it 'extracts novelty from novel traces count' do
      client.update_motivation(tick_results: { memory_retrieval: { novel_traces: 8 } })
      expect(client.motivation_store.drive_state.drive_level(:novelty)).to be >= 0.0
    end

    it 'extracts obligation from pending tasks' do
      client.update_motivation(tick_results: { scheduler: { pending_tasks: 10 } })
      expect(client.motivation_store.drive_state.drive_level(:obligation)).to be > 0.0
    end

    it 'extracts survival from extinction level' do
      client.update_motivation(tick_results: { extinction: { level: 4 } })
      expect(client.motivation_store.drive_state.drive_level(:survival)).to be > 0.5
    end

    it 'lowers autonomy from constrained consent tier' do
      initial = client.motivation_store.drive_state.drive_level(:autonomy)
      client.update_motivation(tick_results: { consent: { tier: :supervised } })
      expect(client.motivation_store.drive_state.drive_level(:autonomy)).to be < initial
    end
  end
end

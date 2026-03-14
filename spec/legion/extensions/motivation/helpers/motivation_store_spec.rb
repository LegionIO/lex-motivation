# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Motivation::Helpers::MotivationStore do
  subject(:store) { described_class.new }

  describe '#initialize' do
    it 'creates a default drive_state' do
      expect(store.drive_state).to be_a(Legion::Extensions::Motivation::Helpers::DriveState)
    end

    it 'starts with no goal motivations' do
      expect(store.goal_motivations).to be_empty
    end

    it 'accepts an injected drive_state' do
      ds = Legion::Extensions::Motivation::Helpers::DriveState.new
      s  = described_class.new(drive_state: ds)
      expect(s.drive_state).to be(ds)
    end
  end

  describe '#commit_goal' do
    it 'commits a goal with valid drives' do
      result = store.commit_goal('goal_1', %i[autonomy competence])
      expect(result).to be true
    end

    it 'stores the goal with drives and energy' do
      store.commit_goal('goal_1', %i[autonomy])
      entry = store.goal_motivations['goal_1']
      expect(entry).to include(:drives, :energy, :committed)
    end

    it 'returns false for empty valid drives' do
      result = store.commit_goal('bad_goal', [:nonexistent_drive])
      expect(result).to be false
    end

    it 'filters invalid drives from list' do
      result = store.commit_goal('mixed', %i[autonomy fake_drive])
      expect(result).to be true
      expect(store.goal_motivations['mixed'][:drives]).to eq([:autonomy])
    end

    it 'overwrites existing goal on recommit' do
      store.commit_goal('goal_a', [:autonomy])
      store.commit_goal('goal_a', [:competence])
      expect(store.goal_motivations['goal_a'][:drives]).to eq([:competence])
    end
  end

  describe '#release_goal' do
    it 'removes the goal from tracking' do
      store.commit_goal('goal_to_remove', [:autonomy])
      store.release_goal('goal_to_remove')
      expect(store.goal_motivations).not_to have_key('goal_to_remove')
    end

    it 'returns true even for unknown goal ids' do
      expect(store.release_goal('nonexistent')).to be true
    end
  end

  describe '#goal_energy' do
    it 'returns 0.0 for unknown goal' do
      expect(store.goal_energy('unknown')).to eq(0.0)
    end

    it 'returns a Float between 0 and 1 for a committed goal' do
      store.commit_goal('energized', %i[autonomy competence])
      energy = store.goal_energy('energized')
      expect(energy).to be_a(Float)
      expect(energy).to be_between(0.0, 1.0)
    end
  end

  describe '#most_motivated_goal' do
    it 'returns nil result when no goals committed' do
      result = store.most_motivated_goal
      expect(result).to be_nil
    end

    it 'returns the goal with highest energy' do
      store.commit_goal('low_goal', [:obligation])
      store.commit_goal('high_goal', %i[autonomy competence relatedness novelty])
      # Signal high drives for high_goal
      %i[autonomy competence relatedness novelty].each do |d|
        5.times { store.drive_state.update_drive(d, 1.0) }
      end
      result = store.most_motivated_goal
      expect(result[:goal_id]).to eq('high_goal')
    end

    it 'includes goal_id, energy, and drives in result' do
      store.commit_goal('g1', [:autonomy])
      result = store.most_motivated_goal
      expect(result).to include(:goal_id, :energy, :drives)
    end
  end

  describe '#burnout_check' do
    it 'returns burnout false initially' do
      result = store.burnout_check
      expect(result[:burnout]).to be false
    end

    it 'returns overall_level in result' do
      result = store.burnout_check
      expect(result[:overall_level]).to be_a(Float)
    end

    it 'returns low_motivation_ticks in result' do
      result = store.burnout_check
      expect(result).to have_key(:low_motivation_ticks)
    end

    it 'increments low_motivation_ticks when level is very low' do
      Legion::Extensions::Motivation::Helpers::Constants::DRIVE_TYPES.each do |d|
        20.times { store.drive_state.update_drive(d, 0.0) }
      end
      store.burnout_check
      result = store.burnout_check
      expect(result[:low_motivation_ticks]).to be >= 1
    end

    it 'detects burnout after 10 consecutive low ticks' do
      Legion::Extensions::Motivation::Helpers::Constants::DRIVE_TYPES.each do |d|
        20.times { store.drive_state.update_drive(d, 0.0) }
      end
      11.times { store.burnout_check }
      result = store.burnout_check
      expect(result[:burnout]).to be true
    end

    it 'resets counter when level recovers' do
      Legion::Extensions::Motivation::Helpers::Constants::DRIVE_TYPES.each do |d|
        20.times { store.drive_state.update_drive(d, 0.0) }
      end
      5.times { store.burnout_check }

      Legion::Extensions::Motivation::Helpers::Constants::DRIVE_TYPES.each do |d|
        10.times { store.drive_state.update_drive(d, 1.0) }
      end
      result = store.burnout_check
      expect(result[:low_motivation_ticks]).to eq(0)
    end
  end

  describe '#stats' do
    it 'returns overall_level' do
      expect(store.stats).to have_key(:overall_level)
    end

    it 'returns current_mode' do
      expect(store.stats).to have_key(:current_mode)
    end

    it 'returns intrinsic_average' do
      expect(store.stats).to have_key(:intrinsic_average)
    end

    it 'returns extrinsic_average' do
      expect(store.stats).to have_key(:extrinsic_average)
    end

    it 'returns amotivated flag' do
      expect(store.stats).to have_key(:amotivated)
    end

    it 'returns goal_count' do
      store.commit_goal('g1', [:autonomy])
      expect(store.stats[:goal_count]).to eq(1)
    end
  end

  describe 'goal cap (MAX_GOALS)' do
    it 'does not exceed MAX_GOALS entries' do
      max = Legion::Extensions::Motivation::Helpers::Constants::MAX_GOALS
      (max + 5).times { |i| store.commit_goal("goal_#{i}", [:autonomy]) }
      expect(store.goal_motivations.size).to be <= max
    end
  end
end

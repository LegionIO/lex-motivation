# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Motivation::Helpers::DriveState do
  subject(:state) { described_class.new }

  describe '#initialize' do
    it 'starts all drives at 0.5' do
      Legion::Extensions::Motivation::Helpers::Constants::DRIVE_TYPES.each do |type|
        expect(state.drives[type][:level]).to eq(0.5)
      end
    end

    it 'starts all drives unsatisfied' do
      state.drives.each_value do |d|
        expect(d[:satisfied]).to be false
      end
    end

    it 'starts with nil last_signal for all drives' do
      state.drives.each_value do |d|
        expect(d[:last_signal]).to be_nil
      end
    end

    it 'initializes all defined drive types' do
      expect(state.drives.keys).to match_array(Legion::Extensions::Motivation::Helpers::Constants::DRIVE_TYPES)
    end
  end

  describe '#update_drive' do
    it 'updates level via EMA' do
      initial = state.drive_level(:autonomy)
      state.update_drive(:autonomy, 1.0)
      expect(state.drive_level(:autonomy)).to be > initial
    end

    it 'clamps signal to 0.0..1.0' do
      state.update_drive(:competence, 5.0)
      expect(state.drive_level(:competence)).to be <= 1.0
    end

    it 'clamps negative signal to 0.0' do
      state.update_drive(:competence, -1.0)
      expect(state.drive_level(:competence)).to be >= 0.0
    end

    it 'marks drive satisfied when level crosses 0.6' do
      10.times { state.update_drive(:autonomy, 1.0) }
      expect(state.satisfied?(:autonomy)).to be true
    end

    it 'sets last_signal timestamp' do
      state.update_drive(:relatedness, 0.8)
      expect(state.drives[:relatedness][:last_signal]).to be_a(Time)
    end

    it 'ignores unknown drive types' do
      expect { state.update_drive(:unknown_drive, 0.5) }.not_to raise_error
    end
  end

  describe '#drive_level' do
    it 'returns level for known drive' do
      expect(state.drive_level(:autonomy)).to eq(0.5)
    end

    it 'returns 0.0 for unknown drive' do
      expect(state.drive_level(:nonexistent)).to eq(0.0)
    end
  end

  describe '#satisfied?' do
    it 'returns false initially' do
      expect(state.satisfied?(:competence)).to be false
    end

    it 'returns false for unknown drive' do
      expect(state.satisfied?(:nonexistent)).to be false
    end

    it 'returns true after sufficiently high signals' do
      10.times { state.update_drive(:competence, 1.0) }
      expect(state.satisfied?(:competence)).to be true
    end
  end

  describe '#intrinsic_average' do
    it 'returns a float' do
      expect(state.intrinsic_average).to be_a(Float)
    end

    it 'reflects only intrinsic drives' do
      Legion::Extensions::Motivation::Helpers::Constants::INTRINSIC_DRIVES.each do |d|
        10.times { state.update_drive(d, 1.0) }
      end
      expect(state.intrinsic_average).to be > state.extrinsic_average
    end
  end

  describe '#extrinsic_average' do
    it 'returns a float' do
      expect(state.extrinsic_average).to be_a(Float)
    end

    it 'reflects only extrinsic drives' do
      Legion::Extensions::Motivation::Helpers::Constants::EXTRINSIC_DRIVES.each do |d|
        10.times { state.update_drive(d, 1.0) }
      end
      expect(state.extrinsic_average).to be > state.intrinsic_average
    end
  end

  describe '#overall_level' do
    it 'starts at 0.5' do
      expect(state.overall_level).to eq(0.5)
    end

    it 'increases when drives are signalled high' do
      initial = state.overall_level
      Legion::Extensions::Motivation::Helpers::Constants::DRIVE_TYPES.each do |d|
        state.update_drive(d, 1.0)
      end
      expect(state.overall_level).to be > initial
    end
  end

  describe '#current_mode' do
    it 'returns :maintenance at initial 0.5' do
      expect(state.current_mode).to eq(:maintenance)
    end

    it 'returns :approach when overall level is high' do
      Legion::Extensions::Motivation::Helpers::Constants::DRIVE_TYPES.each do |d|
        10.times { state.update_drive(d, 1.0) }
      end
      expect(state.current_mode).to eq(:approach)
    end

    it 'returns :dormant when overall level is very low' do
      Legion::Extensions::Motivation::Helpers::Constants::DRIVE_TYPES.each do |d|
        20.times { state.update_drive(d, 0.0) }
      end
      expect(state.current_mode).to eq(:dormant)
    end

    it 'returns one of the defined modes' do
      modes = Legion::Extensions::Motivation::Helpers::Constants::MOTIVATION_MODES
      expect(modes).to include(state.current_mode)
    end
  end

  describe '#decay_all' do
    it 'decreases all drive levels' do
      initial_levels = state.drives.transform_values { |d| d[:level] }
      state.decay_all
      state.drives.each do |type, d|
        expect(d[:level]).to be <= initial_levels[type]
      end
    end

    it 'does not drop drives below 0.0' do
      20.times { state.decay_all }
      state.drives.each_value do |d|
        expect(d[:level]).to be >= 0.0
      end
    end
  end

  describe '#amotivated?' do
    it 'returns false at initial levels' do
      expect(state.amotivated?).to be false
    end

    it 'returns true when all drives are very low' do
      Legion::Extensions::Motivation::Helpers::Constants::DRIVE_TYPES.each do |d|
        20.times { state.update_drive(d, 0.0) }
      end
      expect(state.amotivated?).to be true
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Motivation::Helpers::Constants do
  describe 'DRIVE_TYPES' do
    it 'defines 6 drive types' do
      expect(described_class::DRIVE_TYPES.size).to eq(6)
    end

    it 'includes autonomy' do
      expect(described_class::DRIVE_TYPES).to include(:autonomy)
    end

    it 'includes competence' do
      expect(described_class::DRIVE_TYPES).to include(:competence)
    end

    it 'includes relatedness' do
      expect(described_class::DRIVE_TYPES).to include(:relatedness)
    end

    it 'includes novelty' do
      expect(described_class::DRIVE_TYPES).to include(:novelty)
    end

    it 'includes obligation' do
      expect(described_class::DRIVE_TYPES).to include(:obligation)
    end

    it 'includes survival' do
      expect(described_class::DRIVE_TYPES).to include(:survival)
    end

    it 'is frozen' do
      expect(described_class::DRIVE_TYPES).to be_frozen
    end
  end

  describe 'MOTIVATION_MODES' do
    it 'defines 4 modes' do
      expect(described_class::MOTIVATION_MODES).to eq(%i[approach avoidance maintenance dormant])
    end

    it 'is frozen' do
      expect(described_class::MOTIVATION_MODES).to be_frozen
    end
  end

  describe 'INTRINSIC_DRIVES' do
    it 'contains autonomy, competence, relatedness, novelty' do
      expect(described_class::INTRINSIC_DRIVES).to contain_exactly(:autonomy, :competence, :relatedness, :novelty)
    end

    it 'is a subset of DRIVE_TYPES' do
      described_class::INTRINSIC_DRIVES.each do |d|
        expect(described_class::DRIVE_TYPES).to include(d)
      end
    end
  end

  describe 'EXTRINSIC_DRIVES' do
    it 'contains obligation and survival' do
      expect(described_class::EXTRINSIC_DRIVES).to contain_exactly(:obligation, :survival)
    end

    it 'is a subset of DRIVE_TYPES' do
      described_class::EXTRINSIC_DRIVES.each do |d|
        expect(described_class::DRIVE_TYPES).to include(d)
      end
    end
  end

  describe 'intrinsic + extrinsic = all drives' do
    it 'covers all drive types without overlap' do
      all = described_class::INTRINSIC_DRIVES + described_class::EXTRINSIC_DRIVES
      expect(all.sort).to eq(described_class::DRIVE_TYPES.sort)
    end
  end

  describe 'thresholds' do
    it 'APPROACH_THRESHOLD is above AVOIDANCE_THRESHOLD' do
      expect(described_class::APPROACH_THRESHOLD).to be > described_class::AVOIDANCE_THRESHOLD
    end

    it 'AVOIDANCE_THRESHOLD is above BURNOUT_THRESHOLD' do
      expect(described_class::AVOIDANCE_THRESHOLD).to be > described_class::BURNOUT_THRESHOLD
    end

    it 'AMOTIVATION_THRESHOLD is defined' do
      expect(described_class::AMOTIVATION_THRESHOLD).to be_a(Float)
    end

    it 'DRIVE_DECAY_RATE is small and positive' do
      expect(described_class::DRIVE_DECAY_RATE).to be > 0.0
      expect(described_class::DRIVE_DECAY_RATE).to be < 0.1
    end

    it 'DRIVE_ALPHA is a valid EMA alpha' do
      expect(described_class::DRIVE_ALPHA).to be > 0.0
      expect(described_class::DRIVE_ALPHA).to be < 1.0
    end
  end

  describe 'MAX_GOALS' do
    it 'is a positive integer' do
      expect(described_class::MAX_GOALS).to be_a(Integer)
      expect(described_class::MAX_GOALS).to be > 0
    end
  end
end

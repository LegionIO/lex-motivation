# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Motivation::Client do
  describe '#initialize' do
    it 'creates a default motivation_store' do
      client = described_class.new
      expect(client.motivation_store).to be_a(Legion::Extensions::Motivation::Helpers::MotivationStore)
    end

    it 'accepts an injected motivation_store' do
      store  = Legion::Extensions::Motivation::Helpers::MotivationStore.new
      client = described_class.new(motivation_store: store)
      expect(client.motivation_store).to be(store)
    end

    it 'ignores unknown kwargs' do
      expect { described_class.new(unknown_key: true) }.not_to raise_error
    end
  end

  describe 'runner integration' do
    let(:client) { described_class.new }

    it { expect(client).to respond_to(:update_motivation) }
    it { expect(client).to respond_to(:signal_drive) }
    it { expect(client).to respond_to(:commit_to_goal) }
    it { expect(client).to respond_to(:release_goal) }
    it { expect(client).to respond_to(:motivation_for) }
    it { expect(client).to respond_to(:most_motivated_goal) }
    it { expect(client).to respond_to(:drive_status) }
    it { expect(client).to respond_to(:motivation_stats) }
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GeneratedPlan, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:trip) }
  end

  describe 'validations' do
    context 'when status is completed' do
      subject(:plan) { build(:generated_plan, status: 'completed', content: '{"test": "data"}') }

      it { is_expected.to validate_presence_of(:content) }
    end

    context 'when status is not completed' do
      subject(:plan) { build(:generated_plan, status: 'pending') }

      it { is_expected.not_to validate_presence_of(:content) }
    end

    describe 'rating validations' do
      subject(:plan) { build(:generated_plan, :completed) }

      it { is_expected.to allow_value(nil).for(:rating) }
      it { is_expected.to allow_value(1).for(:rating) }
      it { is_expected.to allow_value(10).for(:rating) }
      it { is_expected.not_to allow_value(0).for(:rating) }
      it { is_expected.not_to allow_value(11).for(:rating) }
      it { is_expected.not_to allow_value(5.5).for(:rating) }
    end

    describe 'rating_only_for_completed validation' do
      context 'when plan is not completed' do
        let(:plan) { build(:generated_plan, status: 'pending', rating: 5) }

        it 'is invalid' do
          expect(plan).not_to be_valid
          expect(plan.errors[:rating]).to include('can only be set for completed plans')
        end
      end

      context 'when plan is completed' do
        let(:plan) { build(:generated_plan, status: 'completed', content: '{"test": "data"}', rating: 5) }

        it 'is valid' do
          expect(plan).to be_valid
        end
      end
    end
  end

  describe 'scopes' do
    describe '.ordered' do
      let!(:plan1) { create(:generated_plan, created_at: 2.days.ago) }
      let!(:plan2) { create(:generated_plan, created_at: 1.day.ago) }
      let!(:plan3) { create(:generated_plan, created_at: Time.current) }

      it 'orders plans by created_at descending' do
        expect(described_class.ordered).to eq([ plan3, plan2, plan1 ])
      end
    end
  end

  describe '#parsed_content' do
    let(:trip) { create(:trip) }

    context 'when content is valid JSON' do
      let(:content_hash) do
        {
          'summary' => {
            'total_cost_usd' => 1000,
            'cost_per_person_usd' => 500,
            'duration_days' => 5,
            'number_of_people' => 2
          },
          'hotels' => [],
          'daily_itinerary' => []
        }
      end
      let(:plan) { create(:generated_plan, trip:, status: 'completed', content: content_hash.to_json) }

      it 'returns an OpenStruct object' do
        expect(plan.parsed_content).to be_a(OpenStruct)
      end

      it 'allows method access to JSON properties' do
        parsed = plan.parsed_content
        expect(parsed.summary).to be_a(OpenStruct)
        expect(parsed.summary.total_cost_usd).to eq(1000)
        expect(parsed.summary.cost_per_person_usd).to eq(500)
        expect(parsed.summary.duration_days).to eq(5)
        expect(parsed.summary.number_of_people).to eq(2)
      end

      it 'caches the parsed content' do
        first_call = plan.parsed_content
        second_call = plan.parsed_content
        expect(first_call.object_id).to eq(second_call.object_id)
      end
    end

    context 'when content is blank' do
      let(:plan) { build(:generated_plan, trip:, content: '') }

      it 'returns nil' do
        expect(plan.parsed_content).to be_nil
      end
    end

    context 'when content is nil' do
      let(:plan) { build(:generated_plan, trip:, content: nil) }

      it 'returns nil' do
        expect(plan.parsed_content).to be_nil
      end
    end

    context 'when content is invalid JSON' do
      let(:plan) { create(:generated_plan, trip:, status: 'completed', content: 'invalid json') }

      it 'returns nil' do
        expect(plan.parsed_content).to be_nil
      end

      it 'logs an error' do
        allow(Rails.logger).to receive(:error)
        plan.parsed_content
        expect(Rails.logger).to have_received(:error).with(/Failed to parse generated plan content/)
      end
    end
  end

  describe 'status transitions' do
    let(:plan) { create(:generated_plan, status: 'pending') }

    describe '#mark_as_generating!' do
      it 'transitions status to generating' do
        expect { plan.mark_as_generating! }.to change(plan, :status).from('pending').to('generating')
      end
    end

    describe '#mark_as_completed!' do
      let(:content_json) { '{"test": "data"}' }

      it 'transitions status to completed and sets content' do
        plan.mark_as_generating!
        expect { plan.mark_as_completed!(content_json) }
          .to change(plan, :status).from('generating').to('completed')
          .and change(plan, :content).to(content_json)
      end
    end

    describe '#mark_as_failed!' do
      it 'transitions status to failed' do
        expect { plan.mark_as_failed! }.to change(plan, :status).from('pending').to('failed')
      end
    end
  end

  describe 'enum status' do
    let(:plan) { build(:generated_plan) }

    it 'provides query methods' do
      plan.status = 'pending'
      expect(plan).to be_pending

      plan.status = 'generating'
      expect(plan).to be_generating

      plan.status = 'completed'
      expect(plan).to be_completed

      plan.status = 'failed'
      expect(plan).to be_failed
    end
  end
end

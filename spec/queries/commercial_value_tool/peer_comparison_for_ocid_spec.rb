require 'rails_helper'

RSpec.describe CommercialValueTool::PeerComparisonForOcid do
  describe '#contract_found?' do
    it 'is true when a contract exists for the OCID' do
      contract = create(:contract, :completed)

      result = described_class.call(contract.ocid)

      expect(result.contract_found?).to be(true)
    end

    it 'is false when no contract exists for the OCID' do
      result = described_class.call('ocds-does-not-exist')

      expect(result.contract_found?).to be(false)
    end
  end

  describe "the target contract's own cashable saving" do
    it 'computes contract_approach, contract_percentage and contract_absolute_value' do
      contract = create(:contract, :completed, amount: 100_000)
      create(:cashable_saving, contract: contract, baseline_approach: 'previous_cost', baseline_value: 120_000)

      result = described_class.call(contract.ocid)

      expect(result.contract_approach).to eq('previous_cost')
      expect(result.contract_percentage).to eq(((120_000 - 100_000) / 120_000.0 * 100).round(1))
      expect(result.contract_absolute_value).to eq(20_000)
    end

    it 'ignores expired cashable savings' do
      contract = create(:contract, :completed, amount: 100_000)
      create(:cashable_saving, contract: contract, baseline_value: 120_000, expired_record: true)

      result = described_class.call(contract.ocid)

      expect(result.contract_approach).to be_nil
      expect(result.contract_percentage).to be_nil
      expect(result.contract_absolute_value).to be_nil
    end

    it 'returns nil for all three when the contract has no cashable saving of its own' do
      contract = create(:contract, :completed)

      result = described_class.call(contract.ocid)

      expect(result.contract_approach).to be_nil
      expect(result.contract_percentage).to be_nil
      expect(result.contract_absolute_value).to be_nil
    end
  end

  describe '#peer_group_averages' do
    it 'computes mean/median/absolute_mean/absolute_median across peer contracts sharing a baseline approach' do
      target = create(:contract, :completed, amount: 100_000)
      peer_one = create(:contract, :completed, amount: 100_000)
      peer_two = create(:contract, :completed, amount: 200_000)
      create(:cashable_saving, contract: peer_one, baseline_approach: 'previous_cost', baseline_value: 120_000)
      create(:cashable_saving, contract: peer_two, baseline_approach: 'previous_cost', baseline_value: 220_000)

      result = described_class.call(target.ocid)
      averages = result.peer_group_averages['previous_cost']

      # percentages: (120000-100000)/120000*100 = 16.667, (220000-200000)/220000*100 = 9.091
      expect(averages.mean).to eq(12.9)
      expect(averages.median).to eq(12.9)
      # absolutes: 20000, 20000
      expect(averages.absolute_mean).to eq(BigDecimal('20000'))
      expect(averages.absolute_median).to eq(BigDecimal('20000'))
    end

    it "excludes the target contract's own row from its own peer averages" do
      target = create(:contract, :completed, amount: 100_000)
      create(:cashable_saving, contract: target, baseline_approach: 'previous_cost', baseline_value: 150_000)
      peer = create(:contract, :completed, amount: 100_000)
      create(:cashable_saving, contract: peer, baseline_approach: 'previous_cost', baseline_value: 120_000)

      result = described_class.call(target.ocid)
      averages = result.peer_group_averages['previous_cost']

      expect(averages.mean).to eq(16.7)
      expect(averages.absolute_mean).to eq(BigDecimal('20000'))
    end

    it 'excludes peers whose contract is not calculation_completed' do
      target = create(:contract, :completed, amount: 100_000)
      peer = create(:contract, calculation_completed: false, amount: 100_000)
      create(:cashable_saving, contract: peer, baseline_approach: 'previous_cost', baseline_value: 120_000)

      result = described_class.call(target.ocid)

      expect(result.peer_group_averages).to eq({})
    end

    it "excludes peers whose contract amount is null" do
      target = create(:contract, :completed, amount: 100_000)
      peer = create(:contract, :completed, amount: nil)
      create(:cashable_saving, contract: peer, baseline_approach: 'previous_cost', baseline_value: 120_000)

      result = described_class.call(target.ocid)

      expect(result.peer_group_averages).to eq({})
    end

    it "excludes peers whose contract amount is zero" do
      target = create(:contract, :completed, amount: 100_000)
      peer = create(:contract, :completed, amount: 0)
      create(:cashable_saving, contract: peer, baseline_approach: 'previous_cost', baseline_value: 120_000)

      result = described_class.call(target.ocid)

      expect(result.peer_group_averages).to eq({})
    end

    it "excludes peers whose contract is expired" do
      target = create(:contract, :completed, amount: 100_000)
      peer = create(:contract, :completed, amount: 100_000, expired_record: true)
      create(:cashable_saving, contract: peer, baseline_approach: 'previous_cost', baseline_value: 120_000)

      result = described_class.call(target.ocid)

      expect(result.peer_group_averages).to eq({})
    end

    it "excludes peers whose cashable saving is expired" do
      target = create(:contract, :completed, amount: 100_000)
      peer = create(:contract, :completed, amount: 100_000)
      create(:cashable_saving, contract: peer, baseline_approach: 'previous_cost', baseline_value: 120_000, expired_record: true)

      result = described_class.call(target.ocid)

      expect(result.peer_group_averages).to eq({})
    end

    it 'returns {} and [] when there are no eligible peers' do
      target = create(:contract, :completed, amount: 100_000)

      result = described_class.call(target.ocid)

      expect(result.peer_group_averages).to eq({})
      expect(result.available_approaches).to eq([])
    end

    it 'groups multiple baseline approaches into separate hash keys' do
      target = create(:contract, :completed, amount: 100_000)
      peer_one = create(:contract, :completed, amount: 100_000)
      peer_two = create(:contract, :completed, amount: 100_000)
      create(:cashable_saving, contract: peer_one, baseline_approach: 'previous_cost', baseline_value: 120_000)
      create(:cashable_saving, contract: peer_two, baseline_approach: 'market_pricing', baseline_value: 130_000)

      result = described_class.call(target.ocid)

      expect(result.available_approaches).to contain_exactly('previous_cost', 'market_pricing')
    end
  end
end

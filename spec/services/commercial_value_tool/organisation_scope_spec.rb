require 'rails_helper'

module CommercialValueTool
  RSpec.describe OrganisationScope do
    describe '.gate_ocid' do
      let(:identity_context) { IdentityContext.new(subject: 'user-1', organisation_id: 'org-1', roles: [], token_metadata: {}) }

      context 'when the ocid and organisation_id both match' do
        let!(:contract) { create(:contract, ocid: 'ocds-match-001', organisation_id: 'org-1') }

        it 'returns the matching contract' do
          result = described_class.gate_ocid(ocid: 'ocds-match-001', identity_context: identity_context)

          expect(result).to eq(contract)
        end
      end

      context 'when the ocid does not exist at all' do
        it 'raises ActiveRecord::RecordNotFound' do
          expect { described_class.gate_ocid(ocid: 'ocds-missing', identity_context: identity_context) }
            .to raise_error(ActiveRecord::RecordNotFound)
        end

        it 'logs a not_found reason' do
          expect(Rails.logger).to receive(:info).with(hash_including(reason: :not_found, ocid: 'ocds-missing'))

          expect { described_class.gate_ocid(ocid: 'ocds-missing', identity_context: identity_context) }
            .to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when the ocid exists but belongs to a different organisation' do
        let!(:contract) { create(:contract, ocid: 'ocds-other-org', organisation_id: 'org-2') }

        it 'raises ActiveRecord::RecordNotFound' do
          expect { described_class.gate_ocid(ocid: 'ocds-other-org', identity_context: identity_context) }
            .to raise_error(ActiveRecord::RecordNotFound)
        end

        it 'logs an out_of_scope reason' do
          expect(Rails.logger).to receive(:info).with(hash_including(reason: :out_of_scope, ocid: 'ocds-other-org'))

          expect { described_class.gate_ocid(ocid: 'ocds-other-org', identity_context: identity_context) }
            .to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      it 'raises the same message SavingsController already uses for a missing contract' do
        expect { described_class.gate_ocid(ocid: 'ocds-missing', identity_context: identity_context) }
          .to raise_error(ActiveRecord::RecordNotFound, "Contract with OCID 'ocds-missing' not found")
      end

      context 'when several contract rows share the ocid within the caller organisation' do
        let!(:older) { create(:contract, ocid: 'ocds-multi', organisation_id: 'org-1', record_inserted_date: 1.day.ago) }
        let!(:newer) { create(:contract, ocid: 'ocds-multi', organisation_id: 'org-1', record_inserted_date: 1.hour.ago) }

        it 'returns the most recently inserted row' do
          result = described_class.gate_ocid(ocid: 'ocds-multi', identity_context: identity_context)

          expect(result).to eq(newer)
        end
      end
    end
  end
end

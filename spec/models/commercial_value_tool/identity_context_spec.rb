require 'rails_helper'

module CommercialValueTool
  RSpec.describe IdentityContext do
    subject(:identity_context) do
      described_class.new(
        subject: 'user-123',
        organisation_id: 'org-1',
        roles: [ 'viewer' ],
        token_metadata: { issuer: 'idam' }
      )
    end

    it 'exposes subject' do
      expect(identity_context.subject).to eq('user-123')
    end

    it 'exposes organisation_id' do
      expect(identity_context.organisation_id).to eq('org-1')
    end

    it 'exposes roles' do
      expect(identity_context.roles).to eq([ 'viewer' ])
    end

    it 'exposes token_metadata' do
      expect(identity_context.token_metadata).to eq({ issuer: 'idam' })
    end

    it 'is immutable' do
      expect { identity_context.organisation_id = 'org-2' }.to raise_error(FrozenError)
    end
  end
end

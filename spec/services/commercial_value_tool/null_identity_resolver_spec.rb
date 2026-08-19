require 'rails_helper'

module CommercialValueTool
  RSpec.describe NullIdentityResolver do
    subject(:resolver) { described_class.new }

    it 'returns nil for a request-like object' do
      request = instance_double(ActionDispatch::Request)

      expect(resolver.resolve(request)).to be_nil
    end

    it 'returns nil for nil' do
      expect(resolver.resolve(nil)).to be_nil
    end

    it 'returns nil regardless of request headers or params' do
      request = instance_double(ActionDispatch::Request, headers: { 'Authorization' => 'Bearer token' }, params: { organisation_id: 'org-1' })

      expect(resolver.resolve(request)).to be_nil
    end
  end
end

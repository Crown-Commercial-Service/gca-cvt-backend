require 'rails_helper'

class OrganisationScopeEnforcementSpecController < ApplicationController
  def unscoped
    render json: { ok: true }
  end
end

RSpec.describe 'Organisation scope enforcement net', type: :request do
  before do
    Rails.application.routes.draw do
      get '/organisation_scope_enforcement_spec/unscoped',
          to: 'organisation_scope_enforcement_spec#unscoped'
    end
  end

  after { Rails.application.reload_routes! }

  context 'when a covered action never calls mark_organisation_scoped! or gate_to_ocid' do
    it 'fails loudly instead of returning the action\'s normal response' do
      stub_identity_context(organisation_id: 'org-1')
      expect(Rails.logger).to receive(:error).with(instance_of(OrganisationScoped::NotAppliedError))

      get '/organisation_scope_enforcement_spec/unscoped'

      expect(response).to have_http_status(:internal_server_error)
      body = JSON.parse(response.body, symbolize_names: true)
      expect(body[:error][:code]).to eq('internal_server_error')
    end
  end

  context 'when no identity context can be resolved' do
    it 'returns 401 and never reaches the scoping check' do
      get '/organisation_scope_enforcement_spec/unscoped'

      expect(response).to have_http_status(:unauthorized)
    end
  end
end

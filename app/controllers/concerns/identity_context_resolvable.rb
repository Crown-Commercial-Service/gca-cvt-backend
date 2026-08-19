module IdentityContextResolvable
  extend ActiveSupport::Concern

  included do
    before_action :resolve_identity_context!
  end

  private

  def resolve_identity_context!
    @current_identity_context = Rails.application.config.x.identity_resolver.resolve(request)

    return if @current_identity_context

    render_error(code: "unauthorised", message: "No identity could be resolved for this request", status: :unauthorized)
  end

  def current_identity_context
    @current_identity_context
  end
end

class ApplicationController < ActionController::API
  include IdentityContextResolvable
  include OrganisationScoped

  rescue_from StandardError, with: :render_internal_error
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from CommercialValueTool::UnknownSavingsType, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
  rescue_from CommercialValueTool::UpdateSavings::MissingSavingsId, with: :render_unprocessable_entity

  private

  def render_error(code:, message:, status:)
    payload = { error: { code: code, message: message } }

    # A rescued error can follow a render the action already performed
    # (e.g. the organisation-scoping after_action net firing once an
    # action has already rendered its own response) — render would raise
    # AbstractController::DoubleRenderError in that case, so overwrite
    # the response directly instead.
    if performed?
      response.status = Rack::Utils.status_code(status)
      response.content_type = "application/json"
      response.body = payload.to_json
    else
      render json: payload, status: status
    end
  end

  def render_not_found(exception)
    render_error(code: "not_found", message: exception.message, status: :not_found)
  end

  def render_unprocessable_entity(exception)
    render_error(code: "unprocessable_entity", message: exception.message, status: :unprocessable_content)
  end

  def render_internal_error(exception)
    Rails.logger.error(exception)
    render_error(code: "internal_server_error", message: "An unexpected error occurred", status: :internal_server_error)
  end
end

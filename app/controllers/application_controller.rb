class ApplicationController < ActionController::API
  rescue_from StandardError, with: :render_internal_error
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
  rescue_from CommercialValueTool::UpdateSavings::MissingSavingsId, with: :render_unprocessable_entity

  private

  def render_error(code:, message:, status:)
    render json: { error: { code: code, message: message } }, status: status
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

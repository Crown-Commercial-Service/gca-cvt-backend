class ApplicationController < ActionController::API
  rescue_from StandardError, with: :render_internal_error

  private

  def render_error(code:, message:, status:)
    render json: { error: { code: code, message: message } }, status: status
  end

  def render_internal_error(exception)
    Rails.logger.error(exception)
    render_error(code: "internal_server_error", message: "An unexpected error occurred", status: :internal_server_error)
  end
end

require "rails_helper"

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("swagger").to_s

  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "Commercial Value Tool API",
        version: "v1"
      },
      servers: [
        { url: "https://{defaultHost}", variables: { defaultHost: { default: "www.example.com" } } }
      ]
    }
  }

  config.openapi_format = :yaml
end
